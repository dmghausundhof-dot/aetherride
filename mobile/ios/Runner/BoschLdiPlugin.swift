import CoreBluetooth
import Flutter
import UIKit

/// Bosch LDI accessory (Spec V1.0): we advertise, the bike connects as central,
/// then we subscribe to Live Data eb21. Raw frames go to Dart for decode.
final class BoschLdiPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
    CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate
{
  private static let serviceUuid = CBUUID(string: "0000eb20-eaa2-11e9-81b4-2a2ae2dbcce4")
  private static let liveUuid = CBUUID(string: "0000eb21-eaa2-11e9-81b4-2a2ae2dbcce4")
  private static let localName = "FlowLine"

  private var eventSink: FlutterEventSink?
  private var pending: FlutterResult?
  private var peripheralManager: CBPeripheralManager?
  private var centralManager: CBCentralManager?
  private var bike: CBPeripheral?
  private var timeout: Timer?
  private var poll: Timer?
  private var subscribed = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = BoschLdiPlugin()
    let method = FlutterMethodChannel(
      name: "com.aetherride/ble_core",
      binaryMessenger: registrar.messenger()
    )
    method.setMethodCallHandler(instance.handle)
    let events = FlutterEventChannel(
      name: "com.aetherride/ble_core/ldi",
      binaryMessenger: registrar.messenger()
    )
    events.setStreamHandler(instance)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "connect":
      let pairing = (call.arguments as? [String: Any])?["pairing"] as? Bool ?? true
      start(pairing: pairing, result: result)
    case "disconnect":
      stop()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start(pairing: Bool, result: @escaping FlutterResult) {
    if subscribed, bike != nil {
      result(true)
      return
    }
    if pending != nil {
      result(false)
      return
    }
    pending = result
    subscribed = false
    emitStatus("ldi_waiting_flow")
    peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    centralManager = CBCentralManager(delegate: self, queue: .main)
    let wait = pairing ? 90.0 : 25.0
    timeout = Timer.scheduledTimer(withTimeInterval: wait, repeats: false) { [weak self] _ in
      self?.failPending("ldi_timeout")
    }
  }

  private func stop() {
    timeout?.invalidate()
    timeout = nil
    poll?.invalidate()
    poll = nil
    failPending(nil)
    if let pm = peripheralManager {
      pm.stopAdvertising()
    }
    if let bike {
      centralManager?.cancelPeripheralConnection(bike)
    }
    bike = nil
    subscribed = false
    peripheralManager = nil
    centralManager = nil
  }

  private func failPending(_ status: String?) {
    if let status { emitStatus(status) }
    let p = pending
    pending = nil
    if let p { p(false) }
  }

  private func succeedPending() {
    timeout?.invalidate()
    timeout = nil
    let p = pending
    pending = nil
    if let p { p(true) }
  }

  private func emitStatus(_ status: String) {
    eventSink?(["status": status])
  }

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    guard peripheral.state == .poweredOn else { return }
    peripheral.startAdvertising([
      CBAdvertisementDataLocalNameKey: BoschLdiPlugin.localName,
      CBAdvertisementDataSolicitedServiceUUIDsKey: [BoschLdiPlugin.serviceUuid],
    ])
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    guard central.state == .poweredOn else { return }
    attachConnectedIfAny()
    poll?.invalidate()
    poll = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      self?.attachConnectedIfAny()
    }
    central.scanForPeripherals(withServices: [BoschLdiPlugin.serviceUuid], options: [
      CBCentralManagerScanOptionAllowDuplicatesKey: false,
    ])
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    attach(peripheral)
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices([BoschLdiPlugin.serviceUuid])
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let svc = peripheral.services?.first(where: { $0.uuid == BoschLdiPlugin.serviceUuid })
    else {
      return
    }
    peripheral.discoverCharacteristics([BoschLdiPlugin.liveUuid], for: svc)
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    guard let chr = service.characteristics?.first(where: { $0.uuid == BoschLdiPlugin.liveUuid })
    else {
      failPending("ldi_timeout")
      return
    }
    peripheral.setNotifyValue(true, for: chr)
    if chr.properties.contains(.read) {
      peripheral.readValue(for: chr)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateNotificationStateFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    if error == nil {
      subscribed = true
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard error == nil, let data = characteristic.value, !data.isEmpty else { return }
    eventSink?(["bytes": FlutterStandardTypedData(bytes: data)])
    if !subscribed {
      subscribed = true
    }
    succeedPending()
  }

  private func attachConnectedIfAny() {
    guard let central = centralManager, bike == nil else { return }
    for p in central.retrieveConnectedPeripherals(withServices: [BoschLdiPlugin.serviceUuid]) {
      attach(p)
      return
    }
  }

  private func attach(_ peripheral: CBPeripheral) {
    if bike != nil { return }
    bike = peripheral
    peripheral.delegate = self
    if peripheral.state == .connected {
      peripheral.discoverServices([BoschLdiPlugin.serviceUuid])
    } else {
      centralManager?.connect(peripheral, options: nil)
    }
  }
}
