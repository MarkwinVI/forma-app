import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// Shared between the app and the widget extension — both targets compile
/// this file, and the struct (name and field types) must stay identical on
/// each side or the system will not route content updates to the UI.
@available(iOS 16.1, *)
struct LiveWorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Name of the exercise the user is on (or resting from).
        var exerciseName: String
        /// 1-based set the user is on, and how many the exercise has.
        var setNumber: Int
        var totalSets: Int
        /// Prescribed target for that set, preformatted: "6 reps" / "20s".
        var repGoalLabel: String
        /// Reference point for the up-counting workout clock. Already
        /// adjusted for pauses (now − elapsed), so the lock screen can run
        /// its own timer without any updates from the app.
        var workoutStartedAt: Date
        /// While paused the clock cannot tick natively, so the app freezes
        /// it: `isPaused` swaps the timer text for this preformatted label.
        var isPaused: Bool
        var pausedElapsedLabel: String?
        /// Present while a rest timer runs; drives the countdown and bar.
        var restStartedAt: Date?
        var restEndsAt: Date?
        /// Every set of every exercise is ticked: the activity stops asking
        /// for the next set and says so, until the workout is finished in
        /// the app.
        var allSetsCompleted: Bool
        /// The set shown was just ticked from the activity's own button:
        /// hold it with a green filled check for a beat, so the tap visibly
        /// landed, before the next update moves on.
        var setJustCompleted: Bool

        var isResting: Bool { restEndsAt != nil }
    }

    /// Static for the whole workout.
    var sessionLabel: String
}
#endif
