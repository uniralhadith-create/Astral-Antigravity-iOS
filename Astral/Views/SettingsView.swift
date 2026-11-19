import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showPairingSheet: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Free Forever Identity Card
                HStack(spacing: 14) {
                    Image("AstralLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Astral IDE")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            Text("مجاني 100%")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AstralPalette.emeraldStatus.opacity(0.24), in: Capsule())
                                .foregroundStyle(AstralPalette.emeraldStatus)
                        }
                        Text("مخصص لـ Google Antigravity — بدون أي اشتراكات أو قيود.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                }
                .padding(16)
                .astralGlass(cornerRadius: 22)

                // Dynamic Island Live Test
                VStack(alignment: .leading, spacing: 10) {
                    Label("اختبار Dynamic Island والعمل بالخلفية", systemImage: "sparkles.tv")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("جرّب تشغيل النشاط الحي على Dynamic Island وشاشة القفل فوراً.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))

                    HStack(spacing: 10) {
                        Button("تشغيل Dynamic Island") {
                            appState.startAgentTask(step: "Antigravity يبني ميزة Liquid Glass...")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AstralPalette.iridescence, in: Capsule())

                        Button("إنهاء") {
                            appState.finishAgentTask(notificationBody: "تم إنهاء تجربة Dynamic Island بنجاح")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .astralGlassCapsule()
                    }
                }
                .padding(16)
                .astralGlass(cornerRadius: 22)

                // Direct Free Cloud Keys (Optional)
                VStack(alignment: .leading, spacing: 10) {
                    Label("مفاتيح السحابة الاختيارية (محفوظة محلياً فقط)", systemImage: "key.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)

                    SecureField("Gemini API Key (مجاني من Google AI Studio)", text: $appState.geminiApiKey)
                        .font(.caption.monospaced())
                        .foregroundStyle(.white)
                        .padding(11)
                        .astralGlass(cornerRadius: 14)
                        .environment(\.layoutDirection, .leftToRight)

                    SecureField("GitHub Personal Access Token (للمستودعات وPRs)", text: $appState.githubToken)
                        .font(.caption.monospaced())
                        .foregroundStyle(.white)
                        .padding(11)
                        .astralGlass(cornerRadius: 14)
                        .environment(\.layoutDirection, .leftToRight)
                }
                .padding(16)
                .astralGlass(cornerRadius: 22)

                Button {
                    showPairingSheet = true
                } label: {
                    Label("إدارة الأجهزة المقترنة (astral-connector)", systemImage: "desktopcomputer")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .astralGlassCapsule()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 96)
        }
    }
}
