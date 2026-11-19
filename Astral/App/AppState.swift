import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    // MARK: - Core Navigation & Onboarding
    @AppStorage("astral.hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @Published var selectedTab: AstralTab = .chat

    // MARK: - Antigravity Mode & Model Settings
    @Published var mode: AntigravityMode = .localPC
    @Published var selectedModel: AntigravityModel = .gemini31ProHigh
    @Published var effort: AgentEffort = .balanced
    @Published var planBeforeChanges: Bool = true
    @Published var connectionState: BridgeConnectionState = .disconnected

    // MARK: - Paired Computers & Projects
    @Published var pairedComputers: [PairedComputer] = []
    @Published var activeComputer: PairedComputer?
    @Published var projects: [AntigravityProject] = [
        AntigravityProject(
            id: "cloud-sandbox",
            name: "Astral Cloud Sandbox",
            path: "~/antigravity-cloud/sandbox",
            mode: .cloudRemote,
            branch: "main",
            previewURL: "https://antigravity.google.com/",
            githubRepo: nil
        )
    ]
    @Published var activeProject: AntigravityProject

    // MARK: - Chat, Commands, Files, Git, Terminal
    @Published var messages: [ChatMessage] = []
    @Published var customSkills: [SlashCommandItem] = SlashCommandItem.defaults
    @Published var files: [WorkspaceFileNode] = []
    @Published var diffs: [GitDiffItem] = []
    @Published var terminalLines: [TerminalLine] = [
        TerminalLine(text: "Astral Remote Terminal — جاهز للاتصال بـ Google Antigravity", isError: false)
    ]
    @Published var isAgentBusy: Bool = false
    @Published var agentProgress: Double = 0.0
    @Published var currentAgentStep: String = "في انتظار أمرك..."

    // MARK: - Credentials (Stored Locally on Device — 100% Free)
    @AppStorage("astral.githubToken") var githubToken: String = ""
    @AppStorage("astral.geminiApiKey") var geminiApiKey: String = ""

    // MARK: - Services
    let bridge = AntigravityBridgeService()
    let liveActivity = LiveActivityManager.shared
    let backgroundManager = BackgroundSessionManager.shared
    let githubService = GitHubService()
    let voiceService = VoiceInputService()

    private var cancellables = Set<AnyCancellable>()
    private var elapsedTimer: Timer?
    private var activeTaskSeconds: Int = 0

    enum AstralTab: String, CaseIterable, Identifiable {
        case chat, code, preview, terminal, settings
        var id: String { rawValue }
    }

    init() {
        self.activeProject = AntigravityProject(
            id: "cloud-sandbox",
            name: "Astral Cloud Sandbox",
            path: "~/antigravity-cloud/sandbox",
            mode: .cloudRemote,
            branch: "main",
            previewURL: "https://antigravity.google.com/",
            githubRepo: nil
        )
        loadSavedComputers()
        setupBridgeCallbacks()
        seedWelcomeMessage()
    }

    private func seedWelcomeMessage() {
        messages = [
            ChatMessage(
                role: .agent,
                content: "أهلاً بك في **Astral** — بيئة العمل المتكاملة والمجانية بالكامل لـ **Google Antigravity**.\n\n• اكتب `/` لاستدعاء أوامر ومهارات Antigravity\n• اربط جهازك بمسح رمز QR من `astral-connector` للعمل على ملفاتك الحقيقية\n• أو بدّل إلى وضع **السحابة** للبرمجة والربط المباشر مع GitHub",
                modelUsed: selectedModel.shortBadge
            )
        ]
    }

    private func setupBridgeCallbacks() {
        bridge.onStateChange = { [weak self] newState in
            Task { @MainActor in
                self?.connectionState = newState
                if case .connected(let host) = newState {
                    self?.terminalLines.append(TerminalLine(text: "✓ متصل بنجاح بجسر Antigravity على \(host)", isError: false))
                    self?.bridge.requestWorkspaceSync()
                }
            }
        }

        bridge.onStreamChunk = { [weak self] chunk, stepLabel, progress in
            Task { @MainActor in
                guard let self else { return }
                self.currentAgentStep = stepLabel
                self.agentProgress = progress
                if let lastIdx = self.messages.indices.last, self.messages[lastIdx].role == .agent, self.messages[lastIdx].isStreaming {
                    self.messages[lastIdx].content += chunk
                } else {
                    self.messages.append(
                        ChatMessage(role: .agent, content: chunk, modelUsed: self.selectedModel.shortBadge, isStreaming: true)
                    )
                }
                self.updateDynamicIsland()
            }
        }

        bridge.onTaskCompleted = { [weak self] summary, changedFiles in
            Task { @MainActor in
                guard let self else { return }
                if let lastIdx = self.messages.indices.last, self.messages[lastIdx].isStreaming {
                    self.messages[lastIdx].isStreaming = false
                    self.messages[lastIdx].changedFiles = changedFiles
                    if !changedFiles.isEmpty {
                        self.messages[lastIdx].actions = [
                            AgentActionButton(id: "undo", title: "تراجع Undo", actionType: "undo", icon: "arrow.uturn.backward"),
                            AgentActionButton(id: "commit", title: "Commit", actionType: "commit", icon: "checkmark.seal"),
                            AgentActionButton(id: "push", title: "Push", actionType: "push", icon: "arrow.up.circle"),
                            AgentActionButton(id: "pr", title: "فتح PR", actionType: "open_pr", icon: "arrow.triangle.pull")
                        ]
                    }
                }
                self.finishAgentTask(notificationBody: summary)
                self.bridge.requestGitDiff()
                self.bridge.requestFileTree()
            }
        }

        bridge.onTerminalOutput = { [weak self] line, isError in
            Task { @MainActor in
                self?.terminalLines.append(TerminalLine(text: line, isError: isError))
            }
        }

        bridge.onFilesReceived = { [weak self] nodes in
            Task { @MainActor in
                self?.files = nodes
            }
        }

        bridge.onDiffsReceived = { [weak self] items in
            Task { @MainActor in
                self?.diffs = items
            }
        }

        bridge.onProjectsReceived = { [weak self] serverProjects in
            Task { @MainActor in
                guard let self else { return }
                let cloud = self.projects.filter { $0.mode == .cloudRemote }
                self.projects = serverProjects + cloud
                if let first = serverProjects.first {
                    self.activeProject = first
                }
            }
        }
    }

    // MARK: - Pairing & Deep Links (astral://pair?ws=...&http=...&token=...&name=...)
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "astral", url.host == "pair",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = comps.queryItems else { return }

        let dict = Dictionary(uniqueKeysWithValues: items.compactMap { item -> (String, String)? in
            guard let val = item.value else { return nil }
            return (item.name, val)
        })

        guard let ws = dict["ws"], let token = dict["token"] else { return }
        let http = dict["http"] ?? ws.replacingOccurrences(of: "ws://", with: "http://").replacingOccurrences(of: "wss://", with: "https://")
        let name = dict["name"] ?? "Antigravity Computer"

        let computer = PairedComputer(
            id: UUID().uuidString,
            name: name,
            wsURL: ws,
            httpURL: http,
            token: token,
            lastConnected: Date()
        )
        pairAndConnect(computer)
    }

    func pairAndConnect(_ computer: PairedComputer) {
        pairedComputers.removeAll { $0.wsURL == computer.wsURL }
        pairedComputers.insert(computer, at: 0)
        activeComputer = computer
        mode = .localPC
        savePairedComputers()
        bridge.connect(to: computer)
    }

    // MARK: - Send Prompt to Antigravity
    func sendPrompt(_ rawText: String) {
        let prompt = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        messages.append(ChatMessage(role: .user, content: prompt))
        startAgentTask(step: planBeforeChanges ? "تجهيز خطة Antigravity..." : "جاري التحليل والتنفيذ...")

        if mode == .localPC, connectionState.isConnected {
            bridge.sendAgentPrompt(
                prompt: prompt,
                model: selectedModel.rawValue,
                effort: effort.rawValue,
                planMode: planBeforeChanges,
                projectPath: activeProject.path
            )
        } else {
            // Antigravity Cloud / Direct Gemini API fallback when PC is not paired
            Task {
                await runCloudPrompt(prompt)
            }
        }
    }

    private func runCloudPrompt(_ prompt: String) async {
        if !geminiApiKey.isEmpty {
            do {
                let reply = try await bridge.callGeminiCloudDirect(
                    apiKey: geminiApiKey,
                    model: selectedModel,
                    prompt: prompt,
                    planMode: planBeforeChanges
                )
                messages.append(ChatMessage(role: .agent, content: reply, modelUsed: selectedModel.shortBadge))
                finishAgentTask(notificationBody: "اكتملت استجابة \(selectedModel.shortBadge)")
                return
            } catch {
                messages.append(ChatMessage(role: .system, content: "تعذر الاتصال السحابي: \(error.localizedDescription)"))
                finishAgentTask(notificationBody: "حدث خطأ في الاتصال السحابي")
                return
            }
        }

        // Guided offline/demo response instructing how to pair PC or add free Gemini API key
        try? await Task.sleep(nanoseconds: 900_000_000)
        currentAgentStep = "جاري معالجة الأمر..."
        agentProgress = 0.65
        updateDynamicIsland()
        try? await Task.sleep(nanoseconds: 800_000_000)

        let guide = """
        تم استلام أمرك بنجاح في وضع **\(mode.title)** عبر **\(selectedModel.displayName)**.

        لتشغيل التنفيذ الفعلي مجاناً 100%:
        1. **للعمل على جهازك (Antigravity Desktop/CLI):** شغّل `npx astral-connector` على جهازك وامسح رمز **QR** من زر الربط أعلى الشاشة.
        2. **للعمل السحابي الفوري بدون كمبيوتر:** أضف مفتاح **Gemini API** المجاني من Google AI Studio داخل **الإعدادات**، أو افتح **Antigravity Remote** الرسمي من تبويب المعاينة.
        """
        messages.append(ChatMessage(role: .agent, content: guide, modelUsed: selectedModel.shortBadge))
        finishAgentTask(notificationBody: "جاهز للخطوة التالية في Astral")
    }

    func executeAgentAction(_ action: AgentActionButton) {
        switch action.actionType {
        case "undo":
            bridge.sendGitAction("undo")
            messages.append(ChatMessage(role: .system, content: "تم إرسال أمر التراجع (Undo) عن التعديلات الأخيرة."))
        case "commit":
            bridge.sendGitAction("commit", message: "Astral Antigravity AI update")
            messages.append(ChatMessage(role: .system, content: "تم تنفيذ Commit للتغييرات بنجاح."))
        case "push":
            bridge.sendGitAction("push")
            messages.append(ChatMessage(role: .system, content: "تم رفع التعديلات (Push) إلى الفرع \(activeProject.branch)."))
        case "open_pr":
            bridge.sendGitAction("open_pr")
            messages.append(ChatMessage(role: .system, content: "تم طلب إنشاء Pull Request للمشروع."))
        default:
            break
        }
    }

    func runTerminalCommand(_ cmd: String) {
        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        terminalLines.append(TerminalLine(text: "$ \(trimmed)", isError: false))
        if connectionState.isConnected {
            bridge.sendTerminalCommand(trimmed)
        } else {
            terminalLines.append(TerminalLine(text: "يرجى ربط جهازك عبر astral-connector لتشغيل أوامر Terminal الحقيقية.", isError: true))
        }
    }

    // MARK: - Dynamic Island & Background Execution Coordination
    func startAgentTask(step: String) {
        isAgentBusy = true
        agentProgress = 0.15
        currentAgentStep = step
        activeTaskSeconds = 0

        backgroundManager.beginExtendedExecution()
        liveActivity.startOrUpdate(
            projectName: activeProject.name,
            sessionId: activeProject.id,
            statusText: "Astral يعمل الآن",
            currentStep: step,
            modelName: selectedModel.shortBadge,
            progress: agentProgress,
            isRunning: true,
            modeLabel: mode.shortLabel,
            changedFilesCount: diffs.count,
            elapsedSeconds: activeTaskSeconds
        )

        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isAgentBusy else { return }
                self.activeTaskSeconds += 1
                if self.activeTaskSeconds % 3 == 0 {
                    self.updateDynamicIsland()
                }
            }
        }
    }

    func updateDynamicIsland() {
        liveActivity.startOrUpdate(
            projectName: activeProject.name,
            sessionId: activeProject.id,
            statusText: isAgentBusy ? "جاري التنفيذ" : "مكتمل ✓",
            currentStep: currentAgentStep,
            modelName: selectedModel.shortBadge,
            progress: agentProgress,
            isRunning: isAgentBusy,
            modeLabel: mode.shortLabel,
            changedFilesCount: diffs.count,
            elapsedSeconds: activeTaskSeconds
        )
    }

    func finishAgentTask(notificationBody: String) {
        isAgentBusy = false
        agentProgress = 1.0
        currentAgentStep = "اكتملت المهمة ✓"
        elapsedTimer?.invalidate()
        updateDynamicIsland()

        backgroundManager.notifyCompletion(title: "Astral — \(activeProject.name)", body: notificationBody)
        backgroundManager.endExtendedExecution()

        Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if !self.isAgentBusy {
                self.liveActivity.endActivity()
            }
        }
    }

    func enterBackground() {
        if isAgentBusy || connectionState.isConnected {
            backgroundManager.scheduleBackgroundRefresh()
            updateDynamicIsland()
        }
    }

    func enterForeground() {
        if let computer = activeComputer, mode == .localPC, !connectionState.isConnected {
            bridge.connect(to: computer)
        }
    }

    // MARK: - Persistence
    private func savePairedComputers() {
        if let data = try? JSONEncoder().encode(pairedComputers) {
            UserDefaults.standard.set(data, forKey: "astral.pairedComputers")
        }
    }

    private func loadSavedComputers() {
        if let data = UserDefaults.standard.data(forKey: "astral.pairedComputers"),
           let list = try? JSONDecoder().decode([PairedComputer].self, from: data) {
            pairedComputers = list
            activeComputer = list.first
        }
    }
}
