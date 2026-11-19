import SwiftUI

struct TerminalView: View {
    @EnvironmentObject var appState: AppState
    @State private var commandInput = ""

    private let quickCommands = ["git status", "npm test", "antigravity --version", "ls -la"]

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickCommands, id: \.self) { cmd in
                        Button(cmd) {
                            appState.runTerminalCommand(cmd)
                        }
                        .font(.caption2.bold().monospaced())
                        .foregroundStyle(AstralPalette.cyanGlow)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .astralGlassCapsule()
                    }
                }
                .padding(.horizontal, 14)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 5) {
                        ForEach(appState.terminalLines) { line in
                            Text(line.text)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(line.isError ? Color.red.opacity(0.95) : AstralPalette.emeraldStatus)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(line.id)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(14)
                    .environment(\.layoutDirection, .leftToRight)
                }
                .astralGlass(cornerRadius: 22, tint: Color.black.opacity(0.55))
                .padding(.horizontal, 14)
                .onChange(of: appState.terminalLines.count) { _, _ in
                    if let last = appState.terminalLines.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            HStack(spacing: 8) {
                Text("$")
                    .font(.headline.bold().monospaced())
                    .foregroundStyle(AstralPalette.emeraldStatus)

                TextField("أدخل أمر Terminal لتشغيله على جهازك...", text: $commandInput)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .environment(\.layoutDirection, .leftToRight)
                    .onSubmit { submit() }

                Button(action: submit) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(AstralPalette.iridescence, in: Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .astralGlassCapsule(tint: Color.black.opacity(0.4))
            .padding(.horizontal, 14)
            .padding(.bottom, 86)
        }
    }

    private func submit() {
        let cmd = commandInput
        commandInput = ""
        appState.runTerminalCommand(cmd)
    }
}
