import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    let onOpenPairing: () -> Void

    @State private var page = 0

    var body: some View {
        ZStack {
            AstralAmbientBackground()

            VStack(spacing: 20) {
                Spacer(minLength: 16)

                // Hero Showcase Visual & Animated Mascot
                ZStack {
                    Image("AstralHeroBanner")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(AstralPalette.glassRim, lineWidth: 1)
                        )
                        .opacity(0.92)

                    AstralMascotMotionView(size: 136, isThinking: true)
                        .offset(y: 62)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)

                VStack(spacing: 10) {
                    Text("مرحباً بك في Astral")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("بيئة العمل المتكاملة والمجانية بالكامل لـ Google Antigravity على iPhone بتصميم Liquid Glass وDynamic Island.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Feature Liquid Glass Cards
                VStack(spacing: 10) {
                    featureRow(icon: "desktopcomputer", title: "ربط فوري بـ Antigravity PC", subtitle: "محادثات متزامنة، أوامر /، طرفية حقيقية وGit Diff")
                    featureRow(icon: "sparkles.tv", title: "Dynamic Island والعمل بالخلفية", subtitle: "متابعة تقدم الوكيل لحظياً حتى عند قفل الشاشة")
                    featureRow(icon: "gift.fill", title: "مجاني 100% ومفتوح بالكامل", subtitle: "بدون اشتراكات شهرية — جسر ربط مفتوح المصدر")
                }
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        onOpenPairing()
                    } label: {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("ربط جهازك الآن (QR / Magic Link)")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AstralPalette.iridescence, in: Capsule())
                        .shadow(color: AstralPalette.cyanGlow.opacity(0.35), radius: 16, y: 8)
                    }

                    Button {
                        onComplete()
                    } label: {
                        Text("ابدأ مباشرة في الوضع السحابي")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white.opacity(0.88))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .astralGlassCapsule()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AstralPalette.cyanGlow)
                .frame(width: 40, height: 40)
                .background(AstralPalette.cyanGlow.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
            Spacer()
        }
        .padding(12)
        .astralGlass(cornerRadius: 18)
    }
}
