import Flutter
import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

/// Bridges the Flutter workout screen to ActivityKit over the
/// `forma/live_activity` method channel: `start`/`update`/`end` come in from
/// Dart, lock-screen button taps go back out as `onAction` calls.
final class LiveWorkoutActivityController {
    private let channel: FlutterMethodChannel

    /// The running activity, stored type-erased because stored properties
    /// cannot carry an availability annotation.
    private var currentActivity: Any?

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "forma/live_activity",
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
        #if canImport(AppIntents)
        LiveWorkoutActionRelay.handler = { [weak self] action in
            self?.channel.invokeMethod("onAction", arguments: action)
        }
        #endif
    }

    private func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        #if canImport(ActivityKit)
        switch call.method {
        case "isSupported":
            if #available(iOS 16.2, *) {
                result(ActivityAuthorizationInfo().areActivitiesEnabled)
            } else {
                result(false)
            }
        case "start":
            if #available(iOS 16.2, *),
               let args = call.arguments as? [String: Any] {
                start(args: args)
            }
            result(nil)
        case "update":
            if #available(iOS 16.2, *),
               let args = call.arguments as? [String: Any] {
                update(args: args)
            }
            result(nil)
        case "end":
            if #available(iOS 16.2, *) {
                end()
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
        #else
        result(FlutterMethodNotImplemented)
        #endif
    }

    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private func start(args: [String: Any]) {
        let attributes = LiveWorkoutActivityAttributes(
            sessionLabel: args["sessionLabel"] as? String ?? "Workout"
        )
        let state = Self.contentState(from: args)
        Task {
            // A workout may start while a stale activity from a crashed or
            // killed session still sits on the lock screen — sweep those.
            for stale in Activity<LiveWorkoutActivityAttributes>.activities {
                await stale.end(nil, dismissalPolicy: .immediate)
            }
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
            } catch {
                // Activities can be disabled per app in Settings; the
                // workout itself is unaffected.
                NSLog("Live Activity start failed: \(error)")
            }
        }
    }

    @available(iOS 16.2, *)
    private func update(args: [String: Any]) {
        guard
            let activity = currentActivity
                as? Activity<LiveWorkoutActivityAttributes>
        else { return }
        let state = Self.contentState(from: args)
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    @available(iOS 16.2, *)
    private func end() {
        currentActivity = nil
        Task {
            for activity in Activity<LiveWorkoutActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    @available(iOS 16.2, *)
    private static func contentState(
        from args: [String: Any]
    ) -> LiveWorkoutActivityAttributes.ContentState {
        func date(_ key: String) -> Date? {
            (args[key] as? NSNumber).map {
                Date(timeIntervalSince1970: $0.doubleValue / 1000)
            }
        }
        return .init(
            exerciseName: args["exerciseName"] as? String ?? "",
            setNumber: args["setNumber"] as? Int ?? 1,
            totalSets: args["totalSets"] as? Int ?? 1,
            repGoalLabel: args["repGoalLabel"] as? String ?? "",
            workoutStartedAt: date("workoutStartedAtMs") ?? Date(),
            isPaused: args["isPaused"] as? Bool ?? false,
            pausedElapsedLabel: args["pausedElapsedLabel"] as? String,
            restStartedAt: date("restStartedAtMs"),
            restEndsAt: date("restEndsAtMs")
        )
    }
    #endif
}
