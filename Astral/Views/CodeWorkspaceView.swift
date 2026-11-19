import SwiftUI

struct CodeWorkspaceView: View {
    @EnvironmentObject var appState: AppState
    @State private var segment: Int = 0 // 0 = Files, 1 = Git Diff
    @State private var selectedFile: WorkspaceFileNode?

    var body: some View {
        VStack(spacing: 12) {
            Picker("عرض الكود", selection: $segment) {
                Text("الملفات (\(appState.files.count))").tag(0)
                Text("التعديلات Diff (\(appState.diffs.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            if segment == 0 {
                filesListView
            } else {
                diffsListView
            }
        }
        .padding(.bottom, 84)
        .sheet(item: $selectedFile) { file in
            codeEditorSheet(file)
        }
    }

    private var filesListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if appState.files.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "folder.badge.gearshape")
                            .font(.largeTitle)
                            .foregroundStyle(AstralPalette.cyanGlow)
                        Text("لا توجد ملفات محمّلة بعد")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("اربط جهازك عبر astral-connector لتصفح وتعديل ملفات مشروعك لحظياً.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                        Button("تحديث قائمة الملفات") {
                            appState.bridge.requestFileTree()
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .astralGlassCapsule()
                    }
                    .padding(28)
                    .astralGlass(cornerRadius: 24)
                    .padding(.horizontal, 16)
                } else {
                    ForEach(appState.files) { node in
                        Button {
                            if !node.isDirectory { selectedFile = node }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: node.isDirectory ? "folder.fill" : "doc.text.fill")
                                    .foregroundStyle(node.isDirectory ? AstralPalette.amberWarning : AstralPalette.cyanGlow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(node.name)
                                        .font(.subheadline.bold().monospaced())
                                        .foregroundStyle(.white)
                                    Text(node.path)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                                Spacer()
                                if let status = node.status {
                                    Text(status)
                                        .font(.caption2.bold().monospaced())
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(AstralPalette.emeraldStatus.opacity(0.25), in: Capsule())
                                        .foregroundStyle(AstralPalette.emeraldStatus)
                                }
                            }
                            .padding(12)
                            .astralGlass(cornerRadius: 16)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    private var diffsListView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                gitActionPill("تراجع Undo", icon: "arrow.uturn.backward", action: "undo")
                gitActionPill("Commit", icon: "checkmark.seal.fill", action: "commit")
                gitActionPill("Push", icon: "arrow.up.circle.fill", action: "push")
                gitActionPill("PR", icon: "arrow.triangle.pull", action: "open_pr")
            }
            .padding(.horizontal, 16)

            ScrollView {
                LazyVStack(spacing: 10) {
                    if appState.diffs.isEmpty {
                        Text("لا توجد تعديلات غير محفوظة (Working tree clean).")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .astralGlass(cornerRadius: 20)
                            .padding(.horizontal, 16)
                    } else {
                        ForEach(appState.diffs) { diff in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(diff.filePath)
                                        .font(.caption.bold().monospaced())
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("+\(diff.additions)")
                                        .font(.caption2.bold().monospaced())
                                        .foregroundStyle(AstralPalette.emeraldStatus)
                                    Text("-\(diff.deletions)")
                                        .font(.caption2.bold().monospaced())
                                        .foregroundStyle(.red)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    Text(diff.patch)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.88))
                                        .environment(\.layoutDirection, .leftToRight)
                                }
                            }
                            .padding(12)
                            .astralGlass(cornerRadius: 18)
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }

    private func gitActionPill(_ title: String, icon: String, action: String) -> some View {
        Button {
            appState.bridge.sendGitAction(action)
        } label: {
            Label(title, systemImage: icon)
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .astralGlassCapsule()
        }
    }

    private func codeEditorSheet(_ file: WorkspaceFileNode) -> some View {
        NavigationStack {
            ScrollView {
                Text(file.content ?? "// يتم تحميل محتوى الملف من جسر Antigravity...")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .environment(\.layoutDirection, .leftToRight)
                    .textSelection(.enabled)
            }
            .background(AstralPalette.deepSpace.ignoresSafeArea())
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
