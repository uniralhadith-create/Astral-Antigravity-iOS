import SwiftUI

// MARK: - Astral iOS 27+ Liquid Glass Design System
enum AstralPalette {
    static let deepSpace = Color(red: 0.02, green: 0.03, blue: 0.08)
    static let midnightGlass = Color(red: 0.05, green: 0.07, blue: 0.15)
    static let cyanGlow = Color(red: 0.28, green: 0.87, blue: 1.0)
    static let electricIndigo = Color(red: 0.42, green: 0.44, blue: 1.0)
    static let cosmicViolet = Color(red: 0.68, green: 0.45, blue: 1.0)
    static let emeraldStatus = Color(red: 0.22, green: 0.90, blue: 0.58)
    static let amberWarning = Color(red: 1.0, green: 0.74, blue: 0.25)

    static let iridescence = LinearGradient(
        colors: [cyanGlow, electricIndigo, cosmicViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassRim = LinearGradient(
        colors: [
            Color.white.opacity(0.45),
            cyanGlow.opacity(0.28),
            cosmicViolet.opacity(0.22),
            Color.white.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Liquid Glass Surface Modifier (iOS 26/27+ Native + Seamless Fallback)
struct AstralLiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var interactive: Bool = false
    var tint: Color = AstralPalette.cyanGlow.opacity(0.08)

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint)
                )
                .glassEffect(
                    interactive ? .regular.interactive() : .regular,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(AstralPalette.glassRim, lineWidth: 0.8)
                )
        } else {
            fallbackGlass(content)
        }
        #else
        fallbackGlass(content)
        #endif
    }

    @ViewBuilder
    private func fallbackGlass(_ content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.14), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AstralPalette.glassRim, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
    }
}

struct AstralGlassCapsuleModifier: ViewModifier {
    var interactive: Bool = true
    var tint: Color = AstralPalette.electricIndigo.opacity(0.16)

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .background(Capsule().fill(tint))
                .glassEffect(interactive ? .regular.interactive() : .regular, in: Capsule())
                .overlay(Capsule().stroke(AstralPalette.glassRim, lineWidth: 0.8))
        } else {
            fallbackCapsule(content)
        }
        #else
        fallbackCapsule(content)
        #endif
    }

    @ViewBuilder
    private func fallbackCapsule(_ content: Content) -> some View {
        content
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(tint))
            )
            .overlay(Capsule().stroke(AstralPalette.glassRim, lineWidth: 0.9))
            .shadow(color: AstralPalette.cyanGlow.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func astralGlass(cornerRadius: CGFloat = 24, interactive: Bool = false, tint: Color = AstralPalette.cyanGlow.opacity(0.06)) -> some View {
        modifier(AstralLiquidGlassModifier(cornerRadius: cornerRadius, interactive: interactive, tint: tint))
    }

    func astralGlassCapsule(interactive: Bool = true, tint: Color = AstralPalette.electricIndigo.opacity(0.15)) -> some View {
        modifier(AstralGlassCapsuleModifier(interactive: interactive, tint: tint))
    }
}

// MARK: - Animated Cosmic Liquid Background
struct AstralAmbientBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                AstralPalette.deepSpace.ignoresSafeArea()

                Circle()
                    .fill(AstralPalette.cyanGlow.opacity(0.18))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: CGFloat(sin(t * 0.35)) * 70 - 90, y: CGFloat(cos(t * 0.25)) * 60 - 220)

                Circle()
                    .fill(AstralPalette.cosmicViolet.opacity(0.20))
                    .frame(width: 380, height: 380)
                    .blur(radius: 100)
                    .offset(x: CGFloat(cos(t * 0.3)) * 80 + 110, y: CGFloat(sin(t * 0.28)) * 70 + 180)

                Circle()
                    .fill(AstralPalette.electricIndigo.opacity(0.14))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(x: CGFloat(sin(t * 0.22)) * 50, y: CGFloat(cos(t * 0.2)) * 50)
            }
            .ignoresSafeArea()
        }
    }
}
