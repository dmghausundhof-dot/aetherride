package com.aetherride.aetherride_mobile

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * sensor_core Android — FIFO batching into 1-s EventChannel blocks (Spec §5.1).
 * Sample-for-sample MethodChannel delivery is forbidden.
 */
class SensorCorePlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, SensorEventListener {

    private lateinit var method: MethodChannel
    private lateinit var events: EventChannel
    private var sensorManager: SensorManager? = null
    private var sink: EventChannel.EventSink? = null
    private val queue = ConcurrentLinkedQueue<Map<String, Any>>()
    private val handler = Handler(Looper.getMainLooper())
    private var flushRunnable: Runnable? = null
    private var sampleRateHz = 100
    private var windowStart = System.currentTimeMillis()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        method = MethodChannel(binding.binaryMessenger, "com.aetherride/sensor_core")
        events = EventChannel(binding.binaryMessenger, "com.aetherride/sensor_core/blocks")
        method.setMethodCallHandler(this)
        events.setStreamHandler(this)
        sensorManager = binding.applicationContext.getSystemService(SensorManager::class.java)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stop()
        method.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                sampleRateHz = call.argument<Int>("sampleRateHz") ?: 100
                start()
                result.success(null)
            }
            "stop" -> {
                stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun start() {
        val sm = sensorManager ?: return
        val accel = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        val gyro = sm.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
        val us = (1_000_000 / sampleRateHz.coerceAtLeast(1))
        accel?.let { sm.registerListener(this, it, us) }
        gyro?.let { sm.registerListener(this, it, us) }
        windowStart = System.currentTimeMillis()
        flushRunnable = object : Runnable {
            override fun run() {
                flushBlock()
                handler.postDelayed(this, 1000)
            }
        }
        handler.postDelayed(flushRunnable!!, 1000)
    }

    private fun stop() {
        sensorManager?.unregisterListener(this)
        flushRunnable?.let { handler.removeCallbacks(it) }
        flushRunnable = null
        queue.clear()
    }

    private fun flushBlock() {
        val end = System.currentTimeMillis()
        val samples = mutableListOf<Map<String, Any>>()
        while (true) {
            val s = queue.poll() ?: break
            samples.add(s)
        }
        val payload = hashMapOf<String, Any>(
            "windowStartMs" to windowStart,
            "windowEndMs" to end,
            "sampleRateHz" to sampleRateHz,
            "samples" to samples,
        )
        windowStart = end
        handler.post { sink?.success(payload) }
    }

    private var lastGyro = floatArrayOf(0f, 0f, 0f)

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_GYROSCOPE -> {
                lastGyro = event.values.clone()
            }
            Sensor.TYPE_ACCELEROMETER -> {
                queue.add(
                    mapOf(
                        "t" to System.currentTimeMillis(),
                        "ax" to event.values[0].toDouble(),
                        "ay" to event.values[1].toDouble(),
                        "az" to event.values[2].toDouble(),
                        "gx" to lastGyro[0].toDouble(),
                        "gy" to lastGyro[1].toDouble(),
                        "gz" to lastGyro[2].toDouble(),
                    )
                )
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
