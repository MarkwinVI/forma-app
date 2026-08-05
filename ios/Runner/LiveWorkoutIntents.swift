import Foundation

#if canImport(AppIntents)
import AppIntents

/// Receives lock-screen button taps inside the app's process. The app sets
/// `handler` at launch; in the widget extension nobody does — which is fine,
/// because `LiveActivityIntent`s always perform in the app, the extension
/// only needs the types so its buttons can reference them.
final class LiveWorkoutActionRelay {
    static var handler: ((String) -> Void)?

    static func post(_ action: String) {
        DispatchQueue.main.async { handler?(action) }
    }
}

/// Ticks off the set currently shown on the Live Activity.
@available(iOS 17.0, *)
struct CompleteSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Set"
    static var isDiscoverable: Bool = false

    init() {}

    func perform() async throws -> some IntentResult {
        LiveWorkoutActionRelay.post("completeSet")
        return .result()
    }
}

/// Adds or removes rest time (−10 / +10 on the Live Activity).
@available(iOS 17.0, *)
struct AdjustRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust Rest"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Seconds")
    var deltaSeconds: Int

    init() {}

    init(deltaSeconds: Int) {
        self.deltaSeconds = deltaSeconds
    }

    func perform() async throws -> some IntentResult {
        LiveWorkoutActionRelay.post(
            deltaSeconds < 0 ? "restMinus10" : "restPlus10"
        )
        return .result()
    }
}

/// Ends the running rest timer early.
@available(iOS 17.0, *)
struct SkipRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip Rest"
    static var isDiscoverable: Bool = false

    init() {}

    func perform() async throws -> some IntentResult {
        LiveWorkoutActionRelay.post("skipRest")
        return .result()
    }
}
#endif
