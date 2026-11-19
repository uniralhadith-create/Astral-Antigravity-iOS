import Foundation
#if canImport(ActivityKit)
import ActivityKit

public struct AstralActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var statusText: String
        public var currentStep: String
        public var modelName: String
        public var progress: Double // 0.0 ... 1.0
        public var isRunning: Bool
        public var modeLabel: String // "PC" or "Cloud"
        public var changedFilesCount: Int
        public var elapsedSeconds: Int

        public init(
            statusText: String,
            currentStep: String,
            modelName: String,
            progress: Double,
            isRunning: Bool,
            modeLabel: String,
            changedFilesCount: Int,
            elapsedSeconds: Int
        ) {
            self.statusText = statusText
            self.currentStep = currentStep
            self.modelName = modelName
            self.progress = progress
            self.isRunning = isRunning
            self.modeLabel = modeLabel
            self.changedFilesCount = changedFilesCount
            self.elapsedSeconds = elapsedSeconds
        }
    }

    public var projectName: String
    public var sessionId: String

    public init(projectName: String, sessionId: String) {
        self.projectName = projectName
        self.sessionId = sessionId
    }
}
#endif
