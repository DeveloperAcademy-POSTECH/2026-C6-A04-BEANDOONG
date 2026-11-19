#if DEVELOP
import CoreBluetooth
import Foundation

/// 개발자 설정에서 선택한 iPad 연동 모드입니다.
enum IPadPracticeMode {
    static let enabledKey = "isIPadPracticeEnabled"
    static let connectionIDKey = "iPadPracticeConnectionID"
    private static let appliedBuildKey = "iPadPracticeAppliedBuild"

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }
    static var connectionID: UUID? {
        let value = UserDefaults.standard.string(forKey: connectionIDKey) ?? ""
        return UUID(uuidString: value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// 이 iPhone을 대상으로 빌드한 연결 설정을 빌드당 한 번 적용합니다.
    static func saveBuildConnectionID(bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        guard let url = bundle.url(forResource: "iPadPairingPreset", withExtension: "txt"),
              let preset = try? String(contentsOf: url, encoding: .utf8) else { return }
        let lines = preset.split(whereSeparator: \.isNewline)
        guard lines.count == 2, let id = UUID(uuidString: String(lines[0])),
              let buildID = UUID(uuidString: String(lines[1])),
              defaults.string(forKey: appliedBuildKey) != buildID.uuidString else { return }
        saveConnectionID(id, defaults: defaults)
        defaults.set(buildID.uuidString, forKey: appliedBuildKey)
    }

    /// Mac에서 실행 인수로 받은 UUID를 이 iPhone의 연동 설정에 저장합니다.
    static func saveLaunchConnectionID(from arguments: [String], defaults: UserDefaults = .standard) {
        guard let flag = arguments.firstIndex(of: "--set-ipad-connection-id"),
              let value = arguments.dropFirst(flag + 1).first,
              let id = UUID(uuidString: value.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        saveConnectionID(id, defaults: defaults)
    }

    /// UUID를 저장하고 iPad 연동 모드를 켭니다.
    private static func saveConnectionID(_ id: UUID, defaults: UserDefaults) {
        defaults.set(id.uuidString, forKey: connectionIDKey)
        defaults.set(true, forKey: enabledKey)
    }
}

/// 등록된 서비스 UUID의 iPad 한 대에서 스티밍 상태를 받습니다.
@MainActor
final class IPadPracticeConnection: NSObject, @preconcurrency CBCentralManagerDelegate, @preconcurrency CBPeripheralDelegate {
    private static let phaseCharacteristicID = CBUUID(string: "44D439CB-F1C9-4BC1-9091-5D600F0A7DC6")
    private let serviceID: CBUUID
    private let onPhase: (PracticePhase) -> Void
    private let onIssue: (String) -> Void
    private var manager: CBCentralManager?
    private var peer: CBPeripheral?
    private var connectedPeerID: UUID?
    private var timeout: Task<Void, Never>?
    private var aerationRefresh: Task<Void, Never>?
    private var lastIssue: String?

    init(connectionID: UUID, onPhase: @escaping (PracticePhase) -> Void, onIssue: @escaping (String) -> Void) {
        serviceID = CBUUID(nsuuid: connectionID)
        self.onPhase = onPhase
        self.onIssue = onIssue
        super.init()
        timeout = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(12)) }
            catch { return }
            self?.report(String(localized: "iPad에 연결하지 못했어요. chicPad가 열려 있고 연결 UUID가 맞는지 확인해 주세요."))
        }
        manager = CBCentralManager(delegate: self, queue: .main)
    }

    /// 연습을 멈추거나 잠시 중단할 때 검색과 연결을 해제합니다.
    func stop() {
        timeout?.cancel()
        aerationRefresh?.cancel()
        peer?.delegate = nil
        if let manager {
            manager.delegate = nil
            if manager.state == .poweredOn {
                manager.stopScan()
                if let peer { manager.cancelPeripheralConnection(peer) }
            }
        }
        peer = nil
        manager = nil
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central === manager else { return }
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [serviceID])
            return
        }

        peer?.delegate = nil
        peer = nil
        switch central.state {
        case .poweredOff: report(String(localized: "iPad를 연결하려면 Bluetooth를 켜 주세요."))
        case .unauthorized: report(String(localized: "설정에서 chic의 Bluetooth 접근을 허용해 주세요."))
        case .unsupported: report(String(localized: "이 기기는 Bluetooth LE를 지원하지 않아요."))
        case .resetting where connectedPeerID != nil: report(String(localized: "iPad 연결이 끊겼어요. 다시 연결을 시도합니다."))
        default: break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard central === manager, peer == nil,
              connectedPeerID == nil || connectedPeerID == peripheral.identifier else { return }
        peer = peripheral
        central.stopScan()
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard peripheral === peer else { return }
        peripheral.delegate = self
        peripheral.discoverServices([serviceID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        reconnect(central, after: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        reconnect(central, after: peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard peripheral === peer else { return }
        guard error == nil, let service = peripheral.services?.first(where: { $0.uuid == serviceID }) else {
            manager?.cancelPeripheralConnection(peripheral)
            return
        }
        peripheral.discoverCharacteristics([Self.phaseCharacteristicID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard peripheral === peer, service.uuid == serviceID else { return }
        guard error == nil, let characteristic = service.characteristics?.first(where: { $0.uuid == Self.phaseCharacteristicID }),
              characteristic.properties.contains(.notify) else {
            manager?.cancelPeripheralConnection(peripheral)
            return
        }
        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral === peer, characteristic.uuid == Self.phaseCharacteristicID else { return }
        guard error == nil, characteristic.isNotifying else {
            manager?.cancelPeripheralConnection(peripheral)
            return
        }
        connectedPeerID = peripheral.identifier
        timeout?.cancel()
        lastIssue = nil
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard peripheral === peer, characteristic.uuid == Self.phaseCharacteristicID,
              characteristic.isNotifying, error == nil, let value = characteristic.value,
              let phase = Self.phase(from: value) else { return }
        onPhase(phase)
        refreshAeration(whileShowing: phase)
    }

    /// 지원하는 피드백 상태만 받아들여 시작·종료 상태가 바뀌지 않게 합니다.
    nonisolated static func phase(from data: Data) -> PracticePhase? {
        guard let raw = String(data: data, encoding: .utf8), let phase = PracticePhase(rawValue: raw),
              phase.isRunning else { return nil }
        return phase
    }

    /// iPad가 같은 공기 주입 상태를 유지할 때도 워치 피드백을 갱신합니다.
    private func refreshAeration(whileShowing phase: PracticePhase) {
        guard phase == .aeration else {
            aerationRefresh?.cancel()
            aerationRefresh = nil
            return
        }
        guard aerationRefresh == nil else { return }
        aerationRefresh = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return }
                guard !Task.isCancelled, let self else { return }
                self.onPhase(.aeration)
            }
        }
    }

    /// 연결이 끊기면 같은 서비스 UUID를 다시 검색합니다.
    private func reconnect(_ central: CBCentralManager, after peripheral: CBPeripheral) {
        guard peripheral === peer else { return }
        peripheral.delegate = nil
        peer = nil
        guard central.state == .poweredOn else { return }
        report(String(localized: "iPad 연결이 끊겼어요. 다시 연결을 시도합니다."))
        central.scanForPeripherals(withServices: [serviceID])
    }

    /// 같은 문제는 다시 연결되기 전까지 한 번만 알립니다.
    private func report(_ message: String) {
        timeout?.cancel()
        refreshAeration(whileShowing: .listening)
        guard message != lastIssue else { return }
        lastIssue = message
        onIssue(message)
    }
}
#endif
