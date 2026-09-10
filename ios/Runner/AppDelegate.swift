import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "com.outtabed.outta_bed/speaker"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "routeAlarmToSpeaker":
        self.routeAlarmToSpeaker()
        result(nil)
      case "restoreAudioRouting":
        self.restoreAudioRouting()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func routeAlarmToSpeaker() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .default, options: [.duckOthers])
      try session.overrideOutputAudioPort(.speaker)
      try session.setActive(true)
    } catch {
      NSLog("OuttaBed: failed to route alarm to speaker: \(error)")
    }
  }

  private func restoreAudioRouting() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.overrideOutputAudioPort(.none)
    } catch {
      NSLog("OuttaBed: failed to restore audio routing: \(error)")
    }
  }
}
