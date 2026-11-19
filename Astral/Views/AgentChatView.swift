import SwiftUI

struct AgentChatView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showPairingSheet: Bool

    @State private var inputText = ""
    @State private var showSlashMenu = false

    private var filteredCommands: [SlashCommandItem] {
        guard inputText.hasPrefix("/") else { return [] }
        let query = inputText.lowercased()
        if query == "/" { return appState.customSkills }
        return appState.customSkills.filter { $0.command.lowercased().contains(query) || $0.title.contains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Model + Plan + Effort Glass Control Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Menu {
                        ForEach(AntigravityModel.allCases) { model in
                            Button {
                                appState.selectedModel = model
                            } label: {
                                Label(model.displayName, systemImage: model.icon)
                            }
                        }
                    } label: {
                        Label(appState.selectedModel.shortBadge, systemImage: appState.selectedModel.icon)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .astralGlassCapsule()
                    }

                    Button {
                        withAnimation(.spring) { appState.planBeforeChanges.toggle() }
                    } label: {
                        Label(appState.planBeforeChanges ? "خطة مسبقة: مفعّل" : "تنفيذ مباشر", systemImage: "list.bullet.clipboard")
                            .font(.caption.bold())
                            .foregroundStyle(appState.planBeforeChanges ? AstralPalette.cyanGlow : .white.opacity(0.75))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .astralGlassCapsule(tint: appState.planBeforeChanges ? AstralPalette.cyanGlow.opacity(0.18) : Color.white.opacity(0.06))
                    }

                    Menu {
                        ForEach(AgentEffort.allCases) { eff in
                            Button(eff.title) { appState.effort = eff }
                        }
                    } label: {
                        Label("الجهد: \(appState.effort.title)", systemImage: "gauge.with.needle")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .astralGlassCapsule()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

            // Messages Stream
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if appState.messages.count <= 1 {
                            VStack(spacing: 12) {
                                AstralMascotMotionView(size: 112, isThinking: appState.isAgentBusy)
                                Text("جاهز للبرمجة مع Antigravity")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .padding(.vertical, 12)
                        }

                        ForEach(appState.messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }

                        if appState.isAgentBusy {
                            HStack(spacing: 10) {
                                AstralOrbitalLoader(size: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appState.currentAgentStep)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                    ProgressView(value: appState.agentProgress)
                                        .tint(AstralPalette.cyanGlow)
                                        .frame(width: 160)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .astralGlass(cornerRadius: 18)
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .onChange(of: appState.messages.count) { _, _ in
                    if let last = appState.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Slash Command Popup ("/")
            if !filteredCommands.isEmpty {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(filteredCommands) { cmd in
                            Button {
                                inputText = "\(cmd.command) "
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: cmd.icon)
                                        .foregroundStyle(AstralPalette.cyanGlow)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 1) {
                                        HStack {
                                            Text(cmd.command)
                                                .font(.caption.bold().monospaced())
                                                .foregroundStyle(AstralPalette.cyanGlow)
                                            Text(cmd.title)
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                        Text(cmd.subtitle)
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.68))
                                    }
                                    Spacer()
                                    Text(cmd.category.rawValue)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.white.opacity(0.1), in: Capsule())
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .padding(10)
                            }
                        }
                    }
                    .padding(6)
                }
                .frame(maxHeight: 210)
                .astralGlass(cornerRadius: 20, tint: Color.black.opacity(0.45))
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }

            // Liquid Glass Composer Bar
            HStack(spacing: 8) {
                Button {
                    if inputText.hasPrefix("/") {
                        inputText = ""
                    } else {
                        inputText = "/"
                    }
                } label: {
                    Text("/")
                        .font(.headline.bold().monospaced())
                        .foregroundStyle(AstralPalette.cyanGlow)
                        .frame(width: 36, height: 36)
                        .astralGlassCapsule()
                }

                TextField("اطلب ميزة أو اكتب / للأوامر...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)

                // Voice Input Button
                Button {
                    appState.voiceService.toggleRecording { text in
                        inputText = text
                    }
                } label: {
                    if appState.voiceService.isRecording {
                        AstralStreamingWave(active: true)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 36, height: 36)
                            .astralGlassCapsule()
                    }
                }

                // Send Button
                Button {
                    let prompt = inputText
                    inputText = ""
                    appState.sendPrompt(prompt)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(AstralPalette.iridescence, in: Circle())
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(8)
            .astralGlass(cornerRadius: 26, interactive: true, tint: Color.black.opacity(0.25))
            .padding(.horizontal, 14)
            .padding(.bottom, 84) // Space for floating Liquid Glass Tab Bar
        }
    }

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.role == .user { Spacer(minLength: 44) }

            VStack(alignment: .leading, spacing: 8) {
                if let model = msg.modelUsed, msg.role == .agent {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(AstralPalette.cyanGlow)
                        Text(model)
                            .font(.caption2.bold())
                            .foregroundStyle(AstralPalette.cyanGlow)
                    }
                }

                Text(.init(msg.content))
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .textSelection(.enabled)

                if !msg.changedFiles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(msg.changedFiles, id: \.self) { file in
                                Label(file, systemImage: "doc.text")
                                    .font(.caption2.monospaced())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.08), in: Capsule())
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                    }
                }

                if !msg.actions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(msg.actions) { action in
                                Button {
                                    appState.executeAgentAction(action)
                                } label: {
                                    Label(action.title, systemImage: action.icon)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .astralGlassCapsule(tint: AstralPalette.cyanGlow.opacity(0.22))
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
            .astralGlass(
                cornerRadius: 20,
                tint: msg.role == .user
                    ? AstralPalette.electricIndigo.opacity(0.28)
                    : (msg.role == .system ? AstralPalette.amberWarning.opacity(0.14) : Color.white.opacity(0.05))
            )

            if msg.role != .user { Spacer(minLength: 24) }
        }
        .padding(.horizontal, 14)
    }
}
