package com.aetherride.aetherride_mobile

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

/**
 * Ambient lux stream for Auto-Sunlight (Plan D).
 * sensors_plus has no AmbientLightEvent yet — TYPE_LIGHT via EventChannel.
 */
class AmbientLightPlugin : FlutterPlugin, EventChannel.StreamHandler, SensorEventListener {
    private lateinit var events: EventChannel
    private var sensorManager: SensorManager? = null
    private var sink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        events = EventChannel(binding.binaryMessenger, "com.aetherride/ambient_light")
        events.setStreamHandler(this)
        sensorManager = binding.applicationContext.getSystemService(SensorManager::class.java)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stop()
        events.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        val sm = sensorManager
        val light = sm?.getDefaultSensor(Sensor.TYPE_LIGHT)
        if (sm == null || light == null) {
            events?.error("NO_SENSOR", "Ambient light sensor unavailable", null)
            return
        }
        sm.registerListener(this, light, SensorManager.SENSOR_DELAY_NORMAL)
    }

    override fun onCancel(arguments: Any?) {
        stop()
    }

    private fun stop() {
        sensorManager?.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_LIGHT) return
        sink?.success(event.values[0].toDouble())
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
