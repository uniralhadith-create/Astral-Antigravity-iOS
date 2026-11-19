import SwiftUI

// MARK: - Animated 3D Motion-Graphics Astral Mascot
struct AstralMascotMotionView: View {
    var size: CGFloat = 156
    var isThinking: Bool = false

    @State private var floatUp = false
    @State private var pulseGlow = false
    @State private var ringRotation: Double = 0

    var body: some View {
        ZStack {
            // Outer orbital aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AstralPalette.cyanGlow.opacity(isThinking ? 0.45 : 0.24),
                            AstralPalette.cosmicViolet.opacity(isThinking ? 0.25 : 0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: size * 0.12,
                        endRadius: size * 0.72
                    )
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .scaleEffect(pulseGlow ? 1.08 : 0.94)

            // Kinetic orbital ring
            Ellipse()
                .stroke(
                    AngularGradient(
                        colors: [AstralPalette.cyanGlow, AstralPalette.cosmicViolet, .clear, AstralPalette.cyanGlow],
                        center: .center
                    ),
                    lineWidth: isThinking ? 2.5 : 1.5
                )
                .frame(width: size * 1.12, height: size * 0.42)
                .rotationEffect(.degrees(ringRotation))
                .rotation3DEffect(.degrees(58), axis: (x: 1, y: 0.25, z: 0))

            // Generated 3D Liquid Glass Mascot Artwork
            Image("AstralMascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AstralPalette.glassRim, lineWidth: 1.2)
                )
                .shadow(color: AstralPalette.cyanGlow.opacity(0.42), radius: 22, x: 0, y: 8)
                .offset(y: floatUp ? -7 : 7)
                .scaleEffect(isThinking ? (pulseGlow ? 1.04 : 0.97) : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                floatUp = true
            }
            withAnimation(.easeInOut(duration: isThinking ? 1.1 : 2.2).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
            withAnimation(.linear(duration: isThinking ? 3.5 : 9.0).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
    }
}

// MARK: - Kinetic Orbital Star Loader (Inspired by User's Logo)
struct AstralOrbitalLoader: View {
    var size: CGFloat = 34

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let rx = canvasSize.width * 0.42
                let ry = canvasSize.height * 0.18

                for i in 0..<4 {
                    let angle = Angle.degrees(Double(i) * 45.0 + t * 55.0)
                    var path = Path()
                    path.addEllipse(in: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))

                    var transform = CGAffineTransform(translationX: center.x, y: center.y)
                    transform = transform.rotated(by: CGFloat(angle.radians))
                    let transformed = path.applying(transform)

                    let color = i % 2 == 0 ? AstralPalette.cyanGlow : AstralPalette.cosmicViolet
                    context.stroke(transformed, with: .color(color.opacity(0.85)), lineWidth: 1.6)
                }

                let dotRadius = size * 0.1
                let core = CGRect(x: center.x - dotRadius, y: center.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
                context.fill(Path(ellipseIn: core), with: .color(.white))
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Liquid Glass Audio / Streaming Wave
struct AstralStreamingWave: View {
    var active: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    let phase = t * 5.0 + Double(index) * 0.7
                    let height = active ? (8 + abs(sin(phase)) * 16) : 5
                    Capsule()
                        .fill(AstralPalette.iridescence)
                        .frame(width: 3.5, height: height)
                }
            }
            .frame(height: 24)
        }
    }
}
