import SwiftUI

struct ProjectPickerView: View {
    @EnvironmentObject private var projectService: FontProjectService
    @Environment(\.dismiss) private var dismiss

    @State private var newProjectName = ""
    @State private var showCreateAlert = false
    @State private var renameTarget: FontProject?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("フォントごとにプロジェクトを分けて、同時進行で作れます。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Section("プロジェクト") {
                    ForEach(projectService.projects) { project in
                        Button {
                            projectService.switchProject(to: project.id)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(project.name)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.warmText)
                                    Text(formattedDate(project.updatedAt))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                Spacer()
                                if project.id == projectService.activeProjectID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                        .swipeActions {
                            Button("名前変更") {
                                renameTarget = project
                                renameText = project.name
                            }
                            .tint(AppTheme.accent)

                            if projectService.projects.count > 1 {
                                Button("削除", role: .destructive) {
                                    projectService.deleteProject(id: project.id)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("プロジェクト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newProjectName = ""
                        showCreateAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("新しいプロジェクト", isPresented: $showCreateAlert) {
                TextField("フォント名", text: $newProjectName)
                Button("作成") {
                    let trimmed = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    projectService.createProject(name: trimmed)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("例：文化祭2025、年賀状、こどもの文字")
            }
            .alert("プロジェクト名を変更", isPresented: renameBinding) {
                TextField("名前", text: $renameText)
                Button("保存") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, let target = renameTarget else {
                        renameTarget = nil
                        return
                    }
                    projectService.renameProject(id: target.id, name: trimmed)
                    renameTarget = nil
                }
                Button("キャンセル", role: .cancel) {
                    renameTarget = nil
                }
            }
        }
    }

    private var renameBinding: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { isPresented in
                if !isPresented { renameTarget = nil }
            }
        )
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
