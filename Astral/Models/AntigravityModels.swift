import Foundation

// MARK: - Workspace Mode (Antigravity Exclusively)
enum AntigravityMode: String, CaseIterable, Identifiable, Codable {
    case localPC = "local"
    case cloudRemote = "cloud"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .localPC: return "جهازك (Antigravity PC)"
        case .cloudRemote: return "السحابة (Antigravity Cloud)"
        }
    }

    var shortLabel: String {
        switch self {
        case .localPC: return "PC"
        case .cloudRemote: return "Cloud"
        }
    }

    var icon: String {
        switch self {
        case .localPC: return "desktopcomputer"
        case .cloudRemote: return "cloud.bolt.fill"
        }
    }
}

// MARK: - Antigravity Supported AI Models
enum AntigravityModel: String, CaseIterable, Identifiable, Codable {
    case gemini31ProHigh = "gemini-3.1-pro-high"
    case gemini31Pro = "gemini-3.1-pro"
    case gemini3Flash = "gemini-3-flash"
    case claudeSonnet = "claude-sonnet-antigravity"
    case claudeOpus = "claude-opus-antigravity"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gemini31ProHigh: return "Gemini 3.1 Pro (High)"
        case .gemini31Pro: return "Gemini 3.1 Pro"
        case .gemini3Flash: return "Gemini 3 Flash"
        case .claudeSonnet: return "Claude Sonnet (Antigravity)"
        case .claudeOpus: return "Claude Opus (Antigravity)"
        }
    }

    var shortBadge: String {
        switch self {
        case .gemini31ProHigh: return "Gemini 3.1 High"
        case .gemini31Pro: return "Gemini 3.1"
        case .gemini3Flash: return "Gemini Flash"
        case .claudeSonnet: return "Claude Sonnet"
        case .claudeOpus: return "Claude Opus"
        }
    }

    var icon: String {
        switch self {
        case .gemini31ProHigh, .gemini31Pro, .gemini3Flash: return "sparkles"
        case .claudeSonnet, .claudeOpus: return "cpu.fill"
        }
    }
}

// MARK: - Agent Effort Level
enum AgentEffort: String, CaseIterable, Identifiable, Codable {
    case fast = "fast"
    case balanced = "balanced"
    case deep = "deep"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fast: return "سريع"
        case .balanced: return "متوازن"
        case .deep: return "عميق"
        }
    }
}

// MARK: - Connection State
enum BridgeConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(hostName: String)
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var label: String {
        switch self {
        case .disconnected: return "غير متصل"
        case .connecting: return "جاري الربط..."
        case .connected(let host): return "متصل بـ \(host)"
        case .error(let msg): return "خطأ: \(msg)"
        }
    }
}

// MARK: - Slash Commands, Workflows & Skills
struct SlashCommandItem: Identifiable, Hashable, Codable {
    let id: String
    let command: String
    let title: String
    let subtitle: String
    let category: Category
    let icon: String

    enum Category: String, Codable {
        case command = "أمر"
        case workflow = "سير عمل"
        case skill = "مهارة"
    }

    static let defaults: [SlashCommandItem] = [
        .init(id: "plan", command: "/plan", title: "خطة قبل التعديل", subtitle: "عرض خطة التنفيذ قبل لمس أي ملف", category: .command, icon: "list.bullet.clipboard"),
        .init(id: "diff", command: "/diff", title: "عرض الفروقات", subtitle: "فحص كل التعديلات الأخيرة في المشروع", category: .command, icon: "doc.text.magnifyingglass"),
        .init(id: "commit", command: "/commit", title: "حفظ التغييرات", subtitle: "توليد رسالة Commit ذكية وحفظ التغييرات", category: .command, icon: "checkmark.seal.fill"),
        .init(id: "push", command: "/push", title: "رفع إلى GitHub", subtitle: "دفع الفرع الحالي للمستودع البعيد", category: .command, icon: "arrow.up.circle.fill"),
        .init(id: "pr", command: "/pr", title: "فتح Pull Request", subtitle: "إنشاء طلب دمج تلقائي مع ملخص التغييرات", category: .workflow, icon: "arrow.triangle.pull"),
        .init(id: "undo", command: "/undo", title: "تراجع عن المهمة", subtitle: "إلغاء آخر تعديل أجراه الوكيل", category: .command, icon: "arrow.uturn.backward.circle"),
        .init(id: "test", command: "/test", title: "تشغيل الاختبارات", subtitle: "فحص المشروع وإصلاح الأخطاء تلقائياً", category: .workflow, icon: "checkmark.shield.fill"),
        .init(id: "refactor", command: "/refactor", title: "إعادة هيكلة نظيفة", subtitle: "تحسين بنية الكود والأداء بدون كسر الوظائف", category: .skill, icon: "wand.and.stars"),
        .init(id: "ui-glass", command: "/ui-glass", title: "مهارة Liquid Glass", subtitle: "تصميم واجهات iOS 27 زجاجية سائلة", category: .skill, icon: "sparkles.rectangle.stack")
    ]
}

// MARK: - Chat & Agent Messages
struct AgentActionButton: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let actionType: String // "approve", "reject", "undo", "commit", "push", "open_pr"
    let icon: String
}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date
    var modelUsed: String?
    var changedFiles: [String]
    var actions: [AgentActionButton]
    var isStreaming: Bool

    enum Role: String, Codable {
        case user
        case agent
        case system
    }

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        timestamp: Date = Date(),
        modelUsed: String? = nil,
        changedFiles: [String] = [],
        actions: [AgentActionButton] = [],
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.modelUsed = modelUsed
        self.changedFiles = changedFiles
        self.actions = actions
        self.isStreaming = isStreaming
    }
}

// MARK: - Project & Session
struct AntigravityProject: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var path: String
    var mode: AntigravityMode
    var branch: String
    var previewURL: String?
    var githubRepo: String?
}

// MARK: - Code Explorer & Diffs
struct WorkspaceFileNode: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let path: String
    let isDirectory: Bool
    var language: String?
    var content: String?
    var status: String? // "M", "A", "D", nil
}

struct GitDiffItem: Identifiable, Codable, Hashable {
    let id: String
    let filePath: String
    let additions: Int
    let deletions: Int
    let patch: String
}

// MARK: - Terminal Line
struct TerminalLine: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let isError: Bool
    let timestamp: Date = Date()
}

// MARK: - Paired Computer Configuration
struct PairedComputer: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var wsURL: String
    var httpURL: String
    var token: String
    var lastConnected: Date
}
