import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    #if canImport(ActivityKit)
    private var currentActivity: Activity<AstralActivityAttributes>?
    #endif

    private init() {}

    func startOrUpdate(
        projectName: String,
        sessionId: String,
        statusText: String,
        currentStep: String,
        modelName: String,
        progress: Double,
        isRunning: Bool,
        modeLabel: String,
        changedFilesCount: Int,
        elapsedSeconds: Int
    ) {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = AstralActivityAttributes.ContentState(
            statusText: statusText,
            currentStep: currentStep,
            modelName: modelName,
            progress: min(max(progress, 0.0), 1.0),
            isRunning: isRunning,
            modeLabel: modeLabel,
            changedFilesCount: changedFilesCount,
            elapsedSeconds: elapsedSeconds
        )

        if let activity = currentActivity {
            Task {
                await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(300)))
            }
        } else {
            let attributes = AstralActivityAttributes(projectName: projectName, sessionId: sessionId)
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(300)),
                    pushType: nil
                )
            } catch {
                print("LiveActivity start error: \(error.localizedDescription)")
            }
        }
        #endif
    }

    func endActivity() {
        #if canImport(ActivityKit)
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.currentActivity = nil
        }
        #endif
    }
}
