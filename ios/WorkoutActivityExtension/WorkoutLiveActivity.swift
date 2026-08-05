import ActivityKit
import SwiftUI
import WidgetKit

/// The in-workout Live Activity: current exercise, set and rep goal while
/// training; countdown, progress bar and rest controls while resting. The
/// buttons are iOS 17+ (interactive Live Activities); on 16.x the same
/// layout renders without them.
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveWorkoutActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(context.state.exerciseName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(subtitle(for: context.state))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    WorkoutClock(state: context.state)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: 56)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isResting {
                        RestControls(state: context.state)
                    } else {
                        ActiveSetRow(state: context.state)
                    }
                }
            } compactLeading: {
                FormaMark()
                    .frame(height: 11)
            } compactTrailing: {
                if let restEndsAt = context.state.restEndsAt {
                    Text(
                        timerInterval: Date.now...max(Date.now, restEndsAt),
                        countsDown: true
                    )
                    .monospacedDigit()
                    .frame(maxWidth: 44)
                    .multilineTextAlignment(.trailing)
                } else {
                    Text("\(context.state.setNumber)/\(context.state.totalSets)")
                }
            } minimal: {
                FormaMark()
                    .frame(height: 9)
            }
        }
    }
}

private func subtitle(for state: LiveWorkoutActivityAttributes.ContentState) -> String {
    if state.isResting {
        return "Next: set \(state.setNumber) of \(state.totalSets) "
            + "(\(state.repGoalLabel))"
    }
    return "Set \(state.setNumber) of \(state.totalSets)"
}

// ── Lock screen ───────────────────────────────────────────────────────

private struct LockScreenView: View {
    let state: LiveWorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                FormaMark()
                    .frame(height: 11)
                Text("Forma")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                WorkoutClock(state: state)
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: 64)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(state.exerciseName)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                Text(subtitle(for: state))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if state.isResting {
                RestProgressBar(state: state)
                RestControls(state: state)
            } else {
                ActiveSetRow(state: state)
            }
        }
        .padding(16)
        .foregroundStyle(.white)
    }
}

// ── Shared pieces ─────────────────────────────────────────────────────

/// The Forma mark — filled disc, bar, ring — drawn in code so it stays
/// crisp at every size the activity needs. Geometry mirrors
/// web/assets/splash-mark.svg (1360 × 480 viewBox).
private struct FormaMark: View {
    var color: Color = Color(red: 0x3C / 255, green: 0x7D / 255, blue: 0xFF / 255)

    var body: some View {
        Canvas { context, size in
            let u = size.height / 480
            context.fill(
                Path(ellipseIn: CGRect(x: 2 * u, y: 8 * u, width: 464 * u, height: 464 * u)),
                with: .color(color)
            )
            context.fill(
                Path(CGRect(x: 374 * u, y: 175 * u, width: 582 * u, height: 130 * u)),
                with: .color(color)
            )
            context.stroke(
                Path(ellipseIn: CGRect(x: 919 * u, y: 41 * u, width: 398 * u, height: 398 * u)),
                with: .color(color),
                lineWidth: 75 * u
            )
        }
        .aspectRatio(1360.0 / 480.0, contentMode: .fit)
    }
}

/// The total-workout clock: ticks up natively, freezes while paused.
private struct WorkoutClock: View {
    let state: LiveWorkoutActivityAttributes.ContentState

    var body: some View {
        if state.isPaused {
            Text(state.pausedElapsedLabel ?? "Paused")
                .monospacedDigit()
        } else {
            Text(
                timerInterval: state.workoutStartedAt...Date.distantFuture,
                countsDown: false
            )
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
        }
    }
}

/// Big rep goal on the left, complete-set button on the right.
private struct ActiveSetRow: View {
    let state: LiveWorkoutActivityAttributes.ContentState

    var body: some View {
        HStack {
            Text(state.repGoalLabel)
                .font(.headline)
            Spacer()
            if #available(iOS 17.0, *) {
                Button(intent: CompleteSetIntent()) {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.bold))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.white)
            }
        }
    }
}

/// The draining rest bar; runs natively between the rest bounds.
private struct RestProgressBar: View {
    let state: LiveWorkoutActivityAttributes.ContentState

    var body: some View {
        if let start = state.restStartedAt, let end = state.restEndsAt,
           start < end {
            ProgressView(
                timerInterval: start...end,
                countsDown: true,
                label: { EmptyView() },
                currentValueLabel: { EmptyView() }
            )
            .progressViewStyle(.linear)
            .tint(.blue)
        }
    }
}

/// −15s · countdown · +15s · Skip. Buttons are iOS 17+; below that the
/// countdown stands alone.
private struct RestControls: View {
    let state: LiveWorkoutActivityAttributes.ContentState

    var body: some View {
        if let restEndsAt = state.restEndsAt {
            HStack(spacing: 10) {
                if #available(iOS 17.0, *) {
                    Button(intent: AdjustRestIntent(deltaSeconds: -15)) {
                        Text("−15s").font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                Spacer(minLength: 0)
                Text(
                    timerInterval: Date.now...max(Date.now, restEndsAt),
                    countsDown: true
                )
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .frame(maxWidth: 72)
                Spacer(minLength: 0)
                if #available(iOS 17.0, *) {
                    Button(intent: AdjustRestIntent(deltaSeconds: 15)) {
                        Text("+15s").font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    Button(intent: SkipRestIntent()) {
                        Text("Skip").font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
        }
    }
}
