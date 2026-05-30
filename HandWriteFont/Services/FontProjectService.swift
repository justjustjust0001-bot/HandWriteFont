import Combine
import Foundation

private struct FontProjectStoreFile: Codable {
    var activeProjectID: UUID
    var projects: [FontProject]
}

@MainActor
final class FontProjectService: ObservableObject {
    @Published private(set) var projects: [FontProject] = []
    @Published private(set) var activeProjectID: UUID
    @Published var storeErrorMessage: String?
    let glyphStorage: GlyphStorageService

    private let rootURL: URL
    private let storeURL: URL
    private var cancellables = Set<AnyCancellable>()

    var activeProject: FontProject {
        if let match = projects.first(where: { $0.id == activeProjectID }) {
            return match
        }
        return projects.first ?? FontProject(id: activeProjectID, name: "マイフォント")
    }

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        rootURL = appSupport.appendingPathComponent("FontMaker", isDirectory: true)
        storeURL = rootURL.appendingPathComponent("projects.json")
        try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let initialProject = FontProject(name: "マイフォント")
        activeProjectID = initialProject.id
        glyphStorage = GlyphStorageService(directoryURL: Self.projectDirectory(rootURL: rootURL, projectID: initialProject.id))

        loadStore(fallbackProject: initialProject)
        repairActiveProjectIfNeeded()
        migrateLegacyGlyphsIfNeeded()
        glyphStorage.reload(at: Self.projectDirectory(rootURL: rootURL, projectID: activeProjectID))

        glyphStorage.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var activeProjectTag: String {
        activeProjectID.uuidString
            .replacingOccurrences(of: "-", with: "")
            .prefix(8)
            .uppercased()
    }

    func markActiveProjectUpdated() {
        guard let index = projects.firstIndex(where: { $0.id == activeProjectID }) else { return }
        projects[index].updatedAt = .now
        persistStore()
    }

    func createProject(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let project = FontProject(name: trimmed)
        projects.append(project)
        persistStore()
        switchProject(to: project.id)
    }

    func switchProject(to id: UUID) {
        guard projects.contains(where: { $0.id == id }) else { return }
        activeProjectID = id
        persistStore()
        glyphStorage.reload(at: Self.projectDirectory(rootURL: rootURL, projectID: id))
    }

    func renameProject(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }

        projects[index].name = trimmed
        projects[index].updatedAt = .now
        persistStore()
    }

    func renameActiveProject(_ name: String) {
        renameProject(id: activeProjectID, name: name)
    }

    func deleteProject(id: UUID) {
        guard projects.count > 1 else { return }
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }

        let directory = Self.projectDirectory(rootURL: rootURL, projectID: id)
        do {
            if FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.removeItem(at: directory)
            }
        } catch {
            storeErrorMessage = "プロジェクトの削除に失敗しました。"
            return
        }

        projects.remove(at: index)
        if activeProjectID == id {
            activeProjectID = projects[0].id
            glyphStorage.reload(at: Self.projectDirectory(rootURL: rootURL, projectID: activeProjectID))
        }
        persistStore()
    }

    private func loadStore(fallbackProject: FontProject) {
        guard
            let data = try? Data(contentsOf: storeURL),
            let store = try? JSONDecoder().decode(FontProjectStoreFile.self, from: data),
            !store.projects.isEmpty
        else {
            projects = [fallbackProject]
            activeProjectID = fallbackProject.id
            persistStore()
            return
        }

        projects = store.projects
        activeProjectID = store.projects.contains(where: { $0.id == store.activeProjectID })
            ? store.activeProjectID
            : store.projects[0].id
    }

    private func repairActiveProjectIfNeeded() {
        guard !projects.isEmpty else { return }
        guard !projects.contains(where: { $0.id == activeProjectID }) else { return }
        activeProjectID = projects[0].id
        persistStore()
    }

    private func persistStore() {
        let store = FontProjectStoreFile(activeProjectID: activeProjectID, projects: projects)
        guard let data = try? JSONEncoder().encode(store) else {
            storeErrorMessage = "プロジェクト情報の保存に失敗しました。"
            return
        }
        do {
            try data.write(to: storeURL, options: .atomic)
        } catch {
            storeErrorMessage = "プロジェクト情報の保存に失敗しました。"
        }
    }

    private func migrateLegacyGlyphsIfNeeded() {
        let legacyURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FontMakerGlyphs", isDirectory: true)
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }

        let targetProject = projects.first(where: { $0.id == activeProjectID }) ?? projects[0]
        let destination = Self.projectDirectory(rootURL: rootURL, projectID: targetProject.id)
        try? FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        guard let files = try? FileManager.default.contentsOfDirectory(at: legacyURL, includingPropertiesForKeys: nil) else {
            return
        }

        var failedFiles: [URL] = []
        for file in files {
            let target = destination.appendingPathComponent(file.lastPathComponent)
            if FileManager.default.fileExists(atPath: target.path) {
                try? FileManager.default.removeItem(at: target)
            }
            do {
                try FileManager.default.moveItem(at: file, to: target)
            } catch {
                failedFiles.append(file)
            }
        }

        let remaining = (try? FileManager.default.contentsOfDirectory(at: legacyURL, includingPropertiesForKeys: nil)) ?? failedFiles
        if remaining.isEmpty {
            try? FileManager.default.removeItem(at: legacyURL)
        }

        if targetProject.id == activeProjectID {
            glyphStorage.reload(at: destination)
        }
        persistStore()
    }

    private static func projectDirectory(rootURL: URL, projectID: UUID) -> URL {
        rootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
    }
}
