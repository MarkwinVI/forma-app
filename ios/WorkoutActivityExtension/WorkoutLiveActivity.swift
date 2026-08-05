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
                Image(systemName: "dumbbell.fill")
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
                    Text("S\(context.state.setNumber)/\(context.state.totalSets)")
                }
            } minimal: {
                Image(systemName: "dumbbell.fill")
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
                Image(systemName: "dumbbell.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Workout")
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
                .font(.title.bold())
            Spacer()
            if #available(iOS 17.0, *) {
                Button(intent: CompleteSetIntent()) {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .frame(width: 44, height: 32)
                }
                .buttonStyle(.bordered)
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
