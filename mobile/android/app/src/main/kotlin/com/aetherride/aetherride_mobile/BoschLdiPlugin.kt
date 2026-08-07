package com.aetherride.aetherride_mobile

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bosch Live Data Interface (LDI) shell — G-1 pending.
 * MethodChannel: com.aetherride/ble_core
 * EventChannel: com.aetherride/ble_core/ldi
 */
class BoschLdiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var method: MethodChannel
    private lateinit var events: EventChannel
    private var sink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        method = MethodChannel(binding.binaryMessenger, "com.aetherride/ble_core")
        events = EventChannel(binding.binaryMessenger, "com.aetherride/ble_core/ldi")
        method.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        method.setMethodCallHandler(null)
        events.setStreamHandler(null)
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> {
                // G-1: real Bosch LDI GATT / SDK not wired yet.
                result.success(false)
            }
            "disconnect" -> result.success(null)
            else -> result.error(
                "UnimplementedError",
                "G-1 pending",
                null,
            )
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
