import Foundation
import UIKit
import BackgroundTasks
import UserNotifications

final class BackgroundSessionManager {
    static let shared = BackgroundSessionManager()

    private let refreshTaskId = "com.astral.antigravity.refresh"
    private let processingTaskId = "com.astral.antigravity.sync"
    private var bgTaskId: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskId, using: nil) { task in
            self.handleRefresh(task: task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingTaskId, using: nil) { task in
            self.handleProcessing(task: task as! BGProcessingTask)
        }
        requestNotificationPermission()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func beginExtendedExecution() {
        guard bgTaskId == .invalid else { return }
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "AstralAntigravityAgentRun") { [weak self] in
            self?.endExtendedExecution()
        }
    }

    func endExtendedExecution() {
        guard bgTaskId != .invalid else { return }
        UIApplication.shared.endBackgroundTask(bgTaskId)
        bgTaskId = .invalid
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    func notifyCompletion(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    private func handleRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        task.setTaskCompleted(success: true)
    }

    private func handleProcessing(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        task.setTaskCompleted(success: true)
    }
}
