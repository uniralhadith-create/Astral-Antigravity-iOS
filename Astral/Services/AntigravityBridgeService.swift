import Foundation

final class AntigravityBridgeService: NSObject, URLSessionWebSocketDelegate {
    var onStateChange: ((BridgeConnectionState) -> Void)?
    var onStreamChunk: ((String, String, Double) -> Void)?
    var onTaskCompleted: ((String, [String]) -> Void)?
    var onTerminalOutput: ((String, Bool) -> Void)?
    var onFilesReceived: (([WorkspaceFileNode]) -> Void)?
    var onDiffsReceived: (([GitDiffItem]) -> Void)?
    var onProjectsReceived: (([AntigravityProject]) -> Void)?

    private var session: URLSession!
    private var webSocketTask: URLSessionWebSocketTask?
    private var currentComputer: PairedComputer?
    private var pingTimer: Timer?
    private var shouldReconnect = false

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.shouldUseExtendedBackgroundIdleMode = true
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }

    func connect(to computer: PairedComputer) {
        disconnect()
        currentComputer = computer
        shouldReconnect = true
        onStateChange?(.connecting)

        guard var comps = URLComponents(string: computer.wsURL) else {
            onStateChange?(.error("عنوان الاتصال غير صالح"))
            return
        }
        var query = comps.queryItems ?? []
        query.append(URLQueryItem(name: "token", value: computer.token))
        comps.queryItems = query

        guard let url = comps.url else {
            onStateChange?(.error("تعذر بناء رابط WebSocket"))
            return
        }

        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()
        receiveNextMessage()
        startHeartbeat()
    }

    func disconnect() {
        shouldReconnect = false
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        onStateChange?(.disconnected)
    }

    // MARK: - Outbound Bridge Commands
    func sendAgentPrompt(prompt: String, model: String, effort: String, planMode: Bool, projectPath: String) {
        sendJSON([
            "type": "agent.prompt",
            "prompt": prompt,
            "model": model,
            "effort": effort,
            "planMode": planMode,
            "projectPath": projectPath
        ])
    }

    func sendTerminalCommand(_ command: String) {
        sendJSON([
            "type": "terminal.exec",
            "command": command
        ])
    }

    func sendGitAction(_ action: String, message: String? = nil) {
        var payload: [String: Any] = [
            "type": "git.action",
            "action": action
        ]
        if let message { payload["message"] = message }
        sendJSON(payload)
    }

    func requestWorkspaceSync() {
        sendJSON(["type": "workspace.sync"])
    }

    func requestFileTree() {
        sendJSON(["type": "files.list"])
    }

    func requestGitDiff() {
        sendJSON(["type": "git.diff"])
    }

    private func sendJSON(_ object: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let str = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(str)) { [weak self] error in
            if let error {
                self?.onStateChange?(.error(error.localizedDescription))
            }
        }
    }

    // MARK: - Inbound Streaming
    private func receiveNextMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingText(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleIncomingText(text)
                    }
                @unknown default:
                    break
                }
                self.receiveNextMessage()
            case .failure(let error):
                self.onStateChange?(.error(error.localizedDescription))
                self.scheduleReconnectIfNeeded()
            }
        }
    }

    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "hello":
            let host = json["hostName"] as? String ?? currentComputer?.name ?? "Antigravity PC"
            onStateChange?(.connected(hostName: host))

        case "agent.chunk":
            let chunk = json["chunk"] as? String ?? ""
            let step = json["step"] as? String ?? "Antigravity يكتب الكود..."
            let progress = json["progress"] as? Double ?? 0.5
            onStreamChunk?(chunk, step, progress)

        case "agent.done":
            let summary = json["summary"] as? String ?? "اكتملت مهمة Antigravity"
            let files = json["changedFiles"] as? [String] ?? []
            onTaskCompleted?(summary, files)

        case "terminal.output":
            let line = json["line"] as? String ?? ""
            let isErr = json["isError"] as? Bool ?? false
            onTerminalOutput?(line, isErr)

        case "files.tree":
            if let rawFiles = json["files"],
               let rawData = try? JSONSerialization.data(withJSONObject: rawFiles),
               let decoded = try? JSONDecoder().decode([WorkspaceFileNode].self, from: rawData) {
                onFilesReceived?(decoded)
            }

        case "git.diffs":
            if let rawDiffs = json["diffs"],
               let rawData = try? JSONSerialization.data(withJSONObject: rawDiffs),
               let decoded = try? JSONDecoder().decode([GitDiffItem].self, from: rawData) {
                onDiffsReceived?(decoded)
            }

        case "workspace.projects":
            if let rawProjects = json["projects"],
               let rawData = try? JSONSerialization.data(withJSONObject: rawProjects),
               let decoded = try? JSONDecoder().decode([AntigravityProject].self, from: rawData) {
                onProjectsReceived?(decoded)
            }

        default:
            break
        }
    }

    // MARK: - Heartbeat & Auto-Reconnect
    private func startHeartbeat() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if error != nil {
                    self?.scheduleReconnectIfNeeded()
                }
            }
        }
    }

    private func scheduleReconnectIfNeeded() {
        guard shouldReconnect, let computer = currentComputer else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self, self.shouldReconnect else { return }
            self.connect(to: computer)
        }
    }

    // MARK: - Direct Antigravity Cloud / Gemini API (Free Key Support)
    func callGeminiCloudDirect(
        apiKey: String,
        model: AntigravityModel,
        prompt: String,
        planMode: Bool
    ) async throws -> String {
        let modelId = model == .gemini3Flash ? "gemini-2.5-flash" : "gemini-2.5-pro"
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(modelId):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrefix = planMode
            ? "You are Astral for Google Antigravity. First output a concise numbered implementation plan, then provide clean, production-ready code."
            : "You are Astral for Google Antigravity. Provide direct, complete, production-ready code."

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": "\(systemPrefix)\n\n\(prompt)"]]]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text
        }
        throw NSError(domain: "AstralCloud", code: -1, userInfo: [NSLocalizedDescriptionKey: "لم يتم استلام رد صالح من Gemini API"])
    }

    // MARK: - URLSessionWebSocketDelegate
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        let host = currentComputer?.name ?? "Antigravity PC"
        onStateChange?(.connected(hostName: host))
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        onStateChange?(.disconnected)
        scheduleReconnectIfNeeded()
    }
}
