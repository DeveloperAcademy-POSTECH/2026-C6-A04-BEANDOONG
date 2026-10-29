//
//  WatchConnection.swift
//
//  iPhone과 Apple Watch 사이의 WatchConnectivity 통신을 담당합니다.
//  연결 확인, 시작·종료 요청과 응답, 최신 연습 상태의 전송 및 재연결 시 동기화를 처리합니다.
//  실제 녹음은 iPhone의 PracticeSession에 위임하고, 화면에서는 공개된 연결·연습 상태를 사용합니다.
//

import Foundation
import Combine
import WatchConnectivity

@MainActor
final class WatchConnection: NSObject, ObservableObject {
    enum Status { case checking, notPaired, appNotInstalled, unavailable, ready }

    @Published private(set) var isReachable = false
    @Published private(set) var hasSynced = false
    @Published private(set) var state = PracticeState()
    @Published var errorMessage: String?
    @Published private(set) var isSending = false

    var onCommand: ((WatchRequest) throws -> PracticeState)?
    private var pending: [UUID: (Result<PracticeState, Error>) -> Void] = [:]
    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func publish(_ state: PracticeState) {
        self.state = state
        guard let session, session.activationState == .activated else { return }
        do {
            let payload = ["state": try JSONEncoder().encode(state)]
            try session.updateApplicationContext(payload)
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil) { _ in
                    // 최신 상태는 applicationContext에도 남아 재연결 시 전달됩니다.
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func check() async -> Status {
        guard let session else { return .notPaired }
        session.activate()
        for _ in 0..<50 {
            if session.activationState == .activated { break }
            if Task.isCancelled { return .unavailable }
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard session.activationState == .activated else { return .unavailable }
        #if os(iOS)
        guard session.isPaired else { return .notPaired }
        guard session.isWatchAppInstalled else { return .appNotInstalled }
        #endif
        do {
            _ = try await request(.sync)
            return .ready
        } catch {
            return .unavailable
        }
    }

    func send(_ command: WatchCommand) async {
        guard !isSending else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            let received = try await request(command)
            apply(received)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func request(_ command: WatchCommand) async throws -> PracticeState {
        guard let session, session.activationState == .activated else {
            throw ConnectionError.message("연결 준비 중이에요. 잠시 후 다시 확인해주세요.")
        }
        #if os(iOS)
        guard session.isReachable else {
            throw ConnectionError.message("Apple Watch에서 chic 앱을 열어주세요.")
        }
        #endif
        // watchOS의 sendMessage는 iPhone 앱을 깨울 수 있습니다. 녹음 시작 가능 여부는 iPhone에서 판단합니다.
        let request = WatchRequest(command: command, sessionID: state.sessionID,
                                   expiresAt: Date().addingTimeInterval(8))
        let data = try JSONEncoder().encode(request)
        let id = UUID()
        return try await withCheckedThrowingContinuation { continuation in
            pending[id] = { continuation.resume(with: $0) }
            session.sendMessage(["request": data], replyHandler: { reply in
                Task { @MainActor in
                    do {
                        if let error = reply["error"] as? String { throw ConnectionError.message(error) }
                        guard let data = reply["state"] as? Data else {
                            throw ConnectionError.message("응답을 확인할 수 없어요.")
                        }
                        let state = try JSONDecoder().decode(PracticeState.self, from: data)
                        self.finish(id, result: .success(state))
                    } catch { self.finish(id, result: .failure(error)) }
                }
            }, errorHandler: { error in
                Task { @MainActor in self.finish(id, result: .failure(error)) }
            })
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(8))
                self.finish(id, result: .failure(ConnectionError.message("연결 응답이 없어요. 두 기기에서 앱을 열고 다시 확인해주세요.")))
            }
        }
    }

    private func finish(_ id: UUID, result: Result<PracticeState, Error>) {
        pending.removeValue(forKey: id)?(result)
    }

    private func apply(_ newState: PracticeState) {
        guard newState.updatedAt >= state.updatedAt else { return }
        state = newState
        hasSynced = true
    }

    private func receive(_ message: [String: Any], reply: (([String: Any]) -> Void)? = nil) {
        do {
            if let data = message["request"] as? Data {
                let request = try JSONDecoder().decode(WatchRequest.self, from: data)
                guard request.expiresAt > Date() else {
                    throw ConnectionError.message("요청 시간이 지났어요. 다시 시도해주세요.")
                }
                #if os(iOS)
                let current = try onCommand?(request) ?? state
                #else
                hasSynced = true
                let current = state
                #endif
                reply?(["state": try JSONEncoder().encode(current)])
            } else if let data = message["state"] as? Data {
                #if os(watchOS)
                apply(try JSONDecoder().decode(PracticeState.self, from: data))
                #endif
            }
        } catch { reply?(["error": error.localizedDescription]) }
    }
}

extension WatchConnection: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            #if os(iOS)
            self.publish(self.state)
            #else
            self.receive(session.receivedApplicationContext)
            await self.send(.sync)
            #endif
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            if session.isReachable {
                #if os(iOS)
                self.publish(self.state)
                #else
                await self.send(.sync)
                #endif
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.receive(message) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in self.receive(message, reply: replyHandler) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.receive(applicationContext) }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.isReachable = session.isReachable }
    }
    #endif
}

nonisolated enum ConnectionError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let text): text }
    }
}
