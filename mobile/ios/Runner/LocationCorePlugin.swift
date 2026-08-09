import CoreLocation
import Flutter
import UIKit

/// location_core iOS — CoreLocation fixes on EventChannel (parity with Android plugin).
/// Foreground tracking; no background service (iOS Background Modes optional later).
final class LocationCorePlugin: NSObject, FlutterPlugin, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var eventSink: FlutterEventSink?
  private var methodChannel: FlutterMethodChannel?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = LocationCorePlugin()
    let method = FlutterMethodChannel(
      name: "com.aetherride/location_core",
      binaryMessenger: registrar.messenger()
    )
    instance.methodChannel = method
    method.setMethodCallHandler(instance.handle)
    let events = FlutterEventChannel(
      name: "com.aetherride/location_core/fixes",
      binaryMessenger: registrar.messenger()
    )
    events.setStreamHandler(instance)
    instance.manager.delegate = instance
    instance.manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    instance.manager.distanceFilter = kCLDistanceFilterNone
    instance.manager.activityType = .fitness
    instance.manager.pausesLocationUpdatesAutomatically = false
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      let status = manager.authorizationStatus
      if status == .notDetermined {
        manager.requestWhenInUseAuthorization()
      }
      manager.startUpdatingLocation()
      result(true)
    case "stop":
      manager.stopUpdatingLocation()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let loc = locations.last, let sink = eventSink else { return }
    sink([
      "lat": loc.coordinate.latitude,
      "lng": loc.coordinate.longitude,
      "accuracyM": loc.horizontalAccuracy,
      "speedMps": max(0, loc.speed),
      "altitudeM": loc.altitude,
      "timestampMs": Int64(loc.timestamp.timeIntervalSince1970 * 1000),
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    NSLog("location_core iOS: %@", error.localizedDescription)
  }
}
