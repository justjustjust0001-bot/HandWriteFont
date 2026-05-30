import SwiftUI

struct CharacterCanvasView: View {
    let character: Character

    @EnvironmentObject private var projectService: FontProjectService
    @EnvironmentObject private var drawingSettings: DrawingSettings

    private var glyphStorage: GlyphStorageService { projectService.glyphStorage }

    @State private var strokes: [DrawingStroke] = []
    @State private var alertMessage: String?
    @State private var showSavedPreview = false
    @State private var savedPreviewImage: UIImage?
    @State private var isEditingExisting = false
    @State private var showClearConfirmation = false

    private var guideStyle: CharacterGuideStyle {
        CharacterGuideStyle.style(for: character)
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            strokeWidthControl
                .padding(.horizontal)

            DrawingCanvasView(
                strokes: $strokes,
                strokeWidth: drawingSettings.strokeWidth,
                guideStyle: guideStyle
            )
            .padding(.horizontal)

            if isEditingExisting {
                Text("保存済みの描画を読み込みました。編集して再保存できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            actionButtons
                .padding(.horizontal)

            if showSavedPreview, let savedPreviewImage {
                savedPreviewSection(image: savedPreviewImage)
            }

            Spacer(minLength: 0)
        }
        .navigationTitle("文字を描く")
        .navigationBarTitleDisplayMode(.inline)
        .alert("保存結果", isPresented: alertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .confirmationDialog("この文字の保存データを削除しますか？", isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                performClear()
            }
            Button("キャンセル", role: .cancel) {}
        }
        .onAppear {
            reloadGlyphState()
        }
        .onChange(of: projectService.activeProjectID) { _, _ in
            reloadGlyphState()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("この文字を書いてください")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(String(character))
                .font(.system(size: 56, weight: .medium, design: .rounded))
                .frame(minHeight: 72)
        }
        .padding(.top, 8)
    }

    private var strokeWidthControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("線の太さ")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(drawingSettings.strokeWidth)) pt")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: $drawingSettings.strokeWidth,
                in: DrawingSettings.widthRange,
                step: 1
            )

            Text("太さの変更は、これから描く線にのみ適用されます。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                if glyphStorage.isSaved(character) {
                    showClearConfirmation = true
                } else {
                    performClear()
                }
            } label: {
                Label("消去", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                saveGlyph()
            } label: {
                Label("保存", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(drawableStrokes.isEmpty)
        }
    }

    private func savedPreviewSection(image: UIImage) -> some View {
        VStack(spacing: 8) {
            Text("保存済みプレビュー")
                .font(.caption)
                .foregroundStyle(.secondary)

            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 96, height: 96)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                }
        }
        .padding(.bottom, 12)
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    alertMessage = nil
                }
            }
        )
    }

    private func performClear() {
        if glyphStorage.isSaved(character) {
            do {
                try glyphStorage.delete(for: character)
                projectService.markActiveProjectUpdated()
            } catch {
                alertMessage = error.localizedDescription
                return
            }
        }
        strokes.removeAll()
        isEditingExisting = false
        showSavedPreview = false
        savedPreviewImage = nil
    }

    private var drawableStrokes: [DrawingStroke] {
        strokes.filter { $0.points.count >= 2 }
    }

    private func saveGlyph() {
        let savableStrokes = drawableStrokes
        guard !savableStrokes.isEmpty else {
            alertMessage = "線が短すぎます。もう少し長く描いてから保存してください。"
            return
        }

        guard let image = DrawingRenderer.renderImage(
            from: savableStrokes,
            size: CanonicalCanvas.size,
            fallbackStrokeWidth: drawingSettings.strokeWidth
        ) else {
            alertMessage = GlyphStorageError.imageEncodingFailed.localizedDescription
            return
        }

        do {
            _ = try glyphStorage.save(
                image: image,
                strokes: savableStrokes,
                canvasSize: CanonicalCanvas.size,
                strokeWidth: drawingSettings.strokeWidth,
                for: character
            )
            projectService.markActiveProjectUpdated()
            savedPreviewImage = image
            showSavedPreview = true
            isEditingExisting = true
            alertMessage = "「\(String(character))」を保存しました。"
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func reloadGlyphState() {
        strokes.removeAll()
        isEditingExisting = false
        showSavedPreview = false
        savedPreviewImage = nil

        guard glyphStorage.isSaved(character) else { return }

        if let (savedStrokes, savedSize, savedWidth) = glyphStorage.strokes(for: character) {
            let normalized = CanonicalCanvas.normalize(
                strokes: savedStrokes.map { stroke in
                    var migrated = stroke
                    if migrated.strokeWidth <= 0 {
                        migrated.strokeWidth = savedWidth
                    }
                    return migrated
                },
                from: savedSize,
                strokeWidth: savedWidth
            )
            strokes = normalized.strokes
            drawingSettings.strokeWidth = min(
                max(normalized.strokeWidth, DrawingSettings.widthRange.lowerBound),
                DrawingSettings.widthRange.upperBound
            )
            isEditingExisting = true
        } else {
            alertMessage = GlyphStorageError.loadFailed.localizedDescription
        }

        if let image = glyphStorage.image(for: character) {
            savedPreviewImage = image
            showSavedPreview = true
        }
    }
}

#Preview {
    NavigationStack {
        CharacterCanvasView(character: "A")
            .environmentObject(FontProjectService())
            .environmentObject(DrawingSettings())
    }
}
