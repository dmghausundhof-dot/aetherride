package com.aetherride.aetherride_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel

/**
 * Foreground Service (location) during Ride — Spec §5.1 location_core.
 * Uses platform LocationManager (no Play Services dependency).
 */
class RideLocationService : Service(), LocationListener {
    private var locationManager: LocationManager? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopTracking()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> startTracking()
        }
        return START_STICKY
    }

    private fun startTracking() {
        ensureChannel()
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }

        val lm = getSystemService(LOCATION_SERVICE) as LocationManager
        locationManager = lm
        try {
            val provider = when {
                lm.isProviderEnabled(LocationManager.GPS_PROVIDER) ->
                    LocationManager.GPS_PROVIDER
                lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ->
                    LocationManager.NETWORK_PROVIDER
                else -> LocationManager.GPS_PROVIDER
            }
            lm.requestLocationUpdates(provider, 1000L, 3f, this)
            lm.getLastKnownLocation(provider)?.let { emit(it) }
        } catch (_: SecurityException) {
            // Permission missing — Flutter should request first.
        }
    }

    private fun stopTracking() {
        try {
            locationManager?.removeUpdates(this)
        } catch (_: Exception) {
        }
        locationManager = null
    }

    override fun onLocationChanged(location: Location) {
        emit(location)
    }

    @Deprecated("Deprecated in Java")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

    override fun onProviderEnabled(provider: String) {}

    override fun onProviderDisabled(provider: String) {}

    private fun emit(loc: Location) {
        val sink = eventSink ?: return
        sink.success(
            mapOf(
                "lat" to loc.latitude,
                "lng" to loc.longitude,
                "accuracyM" to loc.accuracy.toDouble(),
                "speedMps" to if (loc.hasSpeed()) loc.speed.toDouble() else 0.0,
                "altitudeM" to if (loc.hasAltitude()) loc.altitude else 0.0,
                "timestampMs" to loc.time,
            ),
        )
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Ride Tracking",
            NotificationManager.IMPORTANCE_LOW,
        )
        mgr.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pi = PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AetherRide")
            .setContentText("Trackt deine Fahrt")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }

    companion object {
        const val ACTION_STOP = "com.aetherride.STOP_RIDE_LOCATION"
        private const val CHANNEL_ID = "aetherride_ride_location"
        private const val NOTIF_ID = 42

        @JvmStatic
        var eventSink: EventChannel.EventSink? = null

        fun start(context: Context) {
            val i = Intent(context, RideLocationService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(i)
            } else {
                context.startService(i)
            }
        }

        fun stop(context: Context) {
            val i = Intent(context, RideLocationService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(i)
        }
    }
}
