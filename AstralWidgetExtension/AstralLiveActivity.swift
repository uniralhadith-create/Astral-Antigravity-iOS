import WidgetKit
import SwiftUI
import ActivityKit

struct AstralLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AstralActivityAttributes.self) { context in
            // MARK: - Lock Screen & Banner Liquid Glass Live Activity
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.28, green: 0.87, blue: 1.0), Color(red: 0.68, green: 0.45, blue: 1.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 34, height: 34)
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Astral · \(context.attributes.projectName)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(context.state.modeLabel)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.24), in: Capsule())
                                .foregroundStyle(Color.cyan)
                        }
                        Text(context.state.currentStep)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Color(red: 0.28, green: 0.87, blue: 1.0))
                        Text(formatElapsed(context.state.elapsedSeconds))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }

                // Liquid Glass Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.28, green: 0.87, blue: 1.0), Color(red: 0.68, green: 0.45, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(12, geo.size.width * context.state.progress))
                    }
                }
                .frame(height: 6)

                HStack {
                    Label(context.state.modelName, systemImage: "cpu")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                    Spacer()
                    if context.state.changedFilesCount > 0 {
                        Label("\(context.state.changedFilesCount) ملفات معدّلة", systemImage: "doc.badge.gearshape")
                            .font(.caption2)
                            .foregroundStyle(Color(red: 0.22, green: 0.90, blue: 0.58))
                    } else {
                        Text(context.state.statusText)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .padding(16)
            .activityBackgroundTint(Color(red: 0.04, green: 0.06, blue: 0.14).opacity(0.92))
            .activitySystemActionForegroundColor(.cyan)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.isRunning ? "atom" : "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.28, green: 0.87, blue: 1.0), Color(red: 0.68, green: 0.45, blue: 1.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Astral")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            Text(context.state.modeLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.cyan)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(Color(red: 0.28, green: 0.87, blue: 1.0))
                        Text(formatElapsed(context.state.elapsedSeconds))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.projectName)
                        .font(.caption.bold())
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        HStack {
                            Text(context.state.currentStep)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(1)
                            Spacer()
                            Text(context.state.modelName)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.12), in: Capsule())
                        }

                        ProgressView(value: context.state.progress)
                            .tint(Color(red: 0.28, green: 0.87, blue: 1.0))
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // MARK: - Compact Leading (Glowing Orbital Glyph)
                Image(systemName: context.state.isRunning ? "atom" : "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.28, green: 0.87, blue: 1.0), Color(red: 0.68, green: 0.45, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } compactTrailing: {
                // MARK: - Compact Trailing (Live Progress Ring + %)
                HStack(spacing: 4) {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(Color(red: 0.28, green: 0.87, blue: 1.0))
                }
            } minimal: {
                // MARK: - Minimal (Orbital Spark)
                Image(systemName: "atom")
                    .foregroundStyle(Color(red: 0.28, green: 0.87, blue: 1.0))
            }
            .keylineTint(Color(red: 0.28, green: 0.87, blue: 1.0))
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
