import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var oauthEventSink: FlutterEventSink?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up event channel for OAuth deep links
    let controller = window?.rootViewController as! FlutterViewController
    let oauthChannel = FlutterEventChannel(name: "songbuddy/oauth", binaryMessenger: controller.binaryMessenger)
    oauthChannel.setStreamHandler(self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if url.scheme == "songbuddy" && url.host == "callback" {
      oauthEventSink?(url.absoluteString)
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    oauthEventSink = events
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    oauthEventSink = nil
    return nil
  }
}
