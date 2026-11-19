import SwiftUI
import UserNotifications

@main
struct AstralApp: App {
    @UIApplicationDelegateAdaptor(AstralAppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .environment(\.layoutDirection, .rightToLeft)
                .onOpenURL { url in
                    appState.handleDeepLink(url)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .background:
                        appState.enterBackground()
                    case .active:
                        appState.enterForeground()
                    default:
                        break
                    }
                }
        }
    }
}

final class AstralAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        BackgroundSessionManager.shared.registerBackgroundTasks()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
