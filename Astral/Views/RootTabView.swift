import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPairingSheet = false
    @Namespace private var tabNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            AstralAmbientBackground()

            VStack(spacing: 0) {
                topLiquidHeader
                Group {
                    switch appState.selectedTab {
                    case .chat:
                        AgentChatView(showPairingSheet: $showPairingSheet)
                    case .code:
                        CodeWorkspaceView()
                    case .preview:
                        LivePreviewView()
                    case .terminal:
                        TerminalView()
                    case .settings:
                        SettingsView(showPairingSheet: $showPairingSheet)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            floatingLiquidTabBar
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
        }
        .sheet(isPresented: $showPairingSheet) {
            PairingView()
                .environmentObject(appState)
                .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: Binding(
            get: { !appState.hasSeenOnboarding },
            set: { if !$0 { appState.hasSeenOnboarding = true } }
        )) {
            OnboardingView(onComplete: {
                appState.hasSeenOnboarding = true
            }, onOpenPairing: {
                appState.hasSeenOnboarding = true
                showPairingSheet = true
            })
        }
    }

    private var topLiquidHeader: some View {
        HStack(spacing: 10) {
            Image("AstralLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AstralPalette.glassRim, lineWidth: 0.8)
                )

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("Astral")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text("Antigravity")
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AstralPalette.iridescence.opacity(0.28), in: Capsule())
                        .foregroundStyle(AstralPalette.cyanGlow)
                }
                Text(appState.activeProject.name)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Mode Switcher Pill (Local PC vs Cloud)
            Menu {
                ForEach(AntigravityMode.allCases) { item in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            appState.mode = item
                        }
                    } label: {
                        Label(item.title, systemImage: item.icon)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: appState.mode.icon)
                        .font(.caption)
                    Text(appState.mode.shortLabel)
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .astralGlassCapsule()
            }

            // QR / Connection Status Button
            Button {
                showPairingSheet = true
            } label: {
                HStack(spacing: 5) {
                    Circle()
                        .fill(appState.connectionState.isConnected ? AstralPalette.emeraldStatus : AstralPalette.amberWarning)
                        .frame(width: 7, height: 7)
                    Image(systemName: "qrcode.viewfinder")
                        .font(.subheadline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .astralGlassCapsule(tint: appState.connectionState.isConnected ? AstralPalette.emeraldStatus.opacity(0.18) : AstralPalette.cyanGlow.opacity(0.12))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var floatingLiquidTabBar: some View {
        HStack(spacing: 4) {
            tabButton(.chat, title: "الوكيل", icon: "sparkles")
            tabButton(.code, title: "الكود", icon: "chevron.left.forwardslash.chevron.right")
            tabButton(.preview, title: "المعاينة", icon: "safari.fill")
            tabButton(.terminal, title: "الطرفية", icon: "terminal.fill")
            tabButton(.settings, title: "الإعدادات", icon: "slider.horizontal.3")
        }
        .padding(6)
        .astralGlassCapsule(interactive: true, tint: Color.black.opacity(0.28))
    }

    private func tabButton(_ tab: AppState.AstralTab, title: String, icon: String) -> some View {
        let isSelected = appState.selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.62))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(AstralPalette.iridescence.opacity(0.32))
                        .overlay(Capsule().stroke(AstralPalette.glassRim, lineWidth: 0.8))
                        .matchedGeometryEffect(id: "ACTIVE_TAB", in: tabNamespace)
                }
            }
        }
    }
}
