import CoreMotion
import Flutter
import UIKit

/// sensor_core iOS — CoreMotion batch → 1-s EventChannel blocks (Spec §5.1).
final class SensorCorePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private let motion = CMMotionManager()
  private var eventSink: FlutterEventSink?
  private var timer: Timer?
  private var samples: [[String: Any]] = []
  private var windowStart: Int64 = 0
  private var sampleRateHz = 100
  private let lock = NSLock()

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SensorCorePlugin()
    let method = FlutterMethodChannel(
      name: "com.aetherride/sensor_core",
      binaryMessenger: registrar.messenger()
    )
    method.setMethodCallHandler(instance.handle)
    let events = FlutterEventChannel(
      name: "com.aetherride/sensor_core/blocks",
      binaryMessenger: registrar.messenger()
    )
    events.setStreamHandler(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      if let args = call.arguments as? [String: Any],
         let hz = args["sampleRateHz"] as? Int {
        sampleRateHz = max(hz, 1)
      }
      start()
      result(nil)
    case "stop":
      stop()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start() {
    windowStart = Int64(Date().timeIntervalSince1970 * 1000)
    motion.deviceMotionUpdateInterval = 1.0 / Double(sampleRateHz)
    motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
      guard let self, let data else { return }
      let t = Int64(Date().timeIntervalSince1970 * 1000)
      let sample: [String: Any] = [
        "t": t,
        "ax": data.userAcceleration.x * 9.81,
        "ay": data.userAcceleration.y * 9.81,
        "az": (data.userAcceleration.z + 1) * 9.81,
        "gx": data.rotationRate.x,
        "gy": data.rotationRate.y,
        "gz": data.rotationRate.z,
      ]
      self.lock.lock()
      self.samples.append(sample)
      self.lock.unlock()
    }
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.flush()
    }
  }

  private func flush() {
    let end = Int64(Date().timeIntervalSince1970 * 1000)
    lock.lock()
    let batch = samples
    samples = []
    let start = windowStart
    windowStart = end
    lock.unlock()
    eventSink?([
      "windowStartMs": start,
      "windowEndMs": end,
      "sampleRateHz": sampleRateHz,
      "samples": batch,
    ] as [String: Any])
  }

  private func stop() {
    timer?.invalidate()
    timer = nil
    motion.stopDeviceMotionUpdates()
    lock.lock()
    samples = []
    lock.unlock()
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
