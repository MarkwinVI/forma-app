import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var liveActivityController: LiveWorkoutActivityController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let flutterController = window?.rootViewController
      as? FlutterViewController {
      liveActivityController = LiveWorkoutActivityController(
        messenger: flutterController.binaryMessenger
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
