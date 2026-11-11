import Foundation
import SwiftData

/// 소리 원본 없이 연습 시간과 분석 구간만 iPhone 내부에 저장합니다.
@MainActor
final class PracticeHistoryStore {
    nonisolated static var directory: URL {
        URL.applicationSupportDirectory.appending(path: "PracticeHistory", directoryHint: .isDirectory)
    }

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(directory: URL = PracticeHistoryStore.directory, legacyDirectory: URL? = nil) throws {
        let files = FileManager.default
        try files.createDirectory(at: directory, withIntermediateDirectories: true)
        var protectedDirectory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try protectedDirectory.setResourceValues(values)
        #if os(iOS)
        // 잠긴 상태에서 워치로 종료해도 기록을 저장할 수 있습니다.
        try Self.protect(directory)
        #endif

        let configuration = ModelConfiguration(url: directory.appending(path: "history.store"), cloudKitDatabase: .none)
        container = try ModelContainer(for: PracticeRecordEntity.self, PracticeSoundSegmentEntity.self,
                                       configurations: configuration)
        context.autosaveEnabled = false
        try migrateLegacyRecords(in: directory)
        if let legacyDirectory, legacyDirectory != directory {
            try migrateLegacyRecords(in: legacyDirectory)
        }
        #if os(iOS)
        for url in try files.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            where url.pathExtension != "m4a" {
            try Self.protect(url)
        }
        #endif
    }

    func records() throws -> [PracticeRecordEntity] {
        try context.fetch(FetchDescriptor<PracticeRecordEntity>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)]))
    }

    func save(record: PracticeRecord, dailyOrder: Int, segments: [DetectedSegment]) throws {
        guard try !records().contains(where: { $0.id == record.id }) else { return }
        context.insert(PracticeRecordEntity(record: record, dailyOrder: dailyOrder, segments: segments))
        try commit()
    }

    /// 연습 기록 하나와 그 소리 구간을 삭제합니다. 없는 id면 아무것도 하지 않습니다.
    func delete(id: UUID) throws {
        guard let entity = try entity(id: id) else { return }
        context.delete(entity)
        try commit()
    }

    /// 바뀐 내용을 저장합니다. 저장에 실패하면 바뀐 내용을 되돌리고 오류를 그대로 전달합니다.
    private func commit() throws {
        do { try context.save() }
        catch { context.rollback(); throw error }
    }

    #if os(iOS)
    /// 기기를 처음 잠금 해제한 뒤에는 잠긴 상태에서도 읽고 쓸 수 있게 파일 보호 등급을 정합니다.
    private static func protect(_ url: URL) throws {
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                                              ofItemAtPath: url.path)
    }
    #endif

    /// 이 id의 기록 하나만 불러옵니다.
    private func entity(id: UUID) throws -> PracticeRecordEntity? {
        try context.fetch(descriptor(id: id)).first
    }

    private func descriptor(id: UUID) -> FetchDescriptor<PracticeRecordEntity> {
        var descriptor = FetchDescriptor<PracticeRecordEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return descriptor
    }

    private func migrateLegacyRecords(in directory: URL) throws {
        let index = directory.appending(path: "records.json")
        guard FileManager.default.fileExists(atPath: index.path) else { return }
        let legacy = try JSONDecoder().decode([PracticeRecord].self, from: Data(contentsOf: index))
            .sorted { $0.startedAt < $1.startedAt }
        var orders: [Date: Int] = [:]
        for record in legacy {
            let day = Calendar.current.startOfDay(for: record.startedAt)
            orders[day, default: 0] += 1
            // 이전 기록에는 분석 구간이 없으므로 소리별 시간은 0으로 둡니다.
            try save(record: record, dailyOrder: orders[day, default: 1], segments: [])
        }
        // 전체 이전에 성공한 뒤에만 이전 인덱스를 제거합니다. 소리 파일은 옮기지 않습니다.
        try FileManager.default.removeItem(at: index)
    }
}
