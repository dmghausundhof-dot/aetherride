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
 * N-05: Pause / Stumm / open-app actions on the ongoing notification.
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
            ACTION_PAUSE -> {
                emitAction("pause")
                // Keep service alive; Flutter toggles pause state.
                refreshNotification()
                return START_STICKY
            }
            ACTION_MUTE -> {
                emitAction("mute")
                muted = !muted
                refreshNotification()
                return START_STICKY
            }
            ACTION_UPDATE_UI -> {
                paused = intent.getBooleanExtra(EXTRA_PAUSED, paused)
                muted = intent.getBooleanExtra(EXTRA_MUTED, muted)
                contentText = intent.getStringExtra(EXTRA_TEXT) ?: contentText
                refreshNotification()
                return START_STICKY
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
        paused = false
        muted = false
        contentText = DEFAULT_TEXT
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

    private fun emitAction(action: String) {
        actionSink?.success(mapOf("action" to action))
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Navigation",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Fahrt-Tracking und Navigation"
            setShowBadge(false)
        }
        mgr.createNotificationChannel(channel)
    }

    private fun refreshNotification() {
        val mgr = getSystemService(NotificationManager::class.java)
        mgr.notify(NOTIF_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("from_ride_notification", true)
        }
        val openPi = PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val pausePi = PendingIntent.getService(
            this,
            1,
            Intent(this, RideLocationService::class.java).setAction(ACTION_PAUSE),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val mutePi = PendingIntent.getService(
            this,
            2,
            Intent(this, RideLocationService::class.java).setAction(ACTION_MUTE),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val pauseLabel = if (paused) "Weiter" else "Pause"
        val muteLabel = if (muted) "Ton an" else "Stumm"
        val body = buildString {
            append(contentText)
            if (paused) append(" · Pause")
            if (muted) append(" · Stumm")
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AetherRide Navigation")
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(openPi)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(0, pauseLabel, pausePi)
            .addAction(0, muteLabel, mutePi)
            .addAction(0, "App", openPi)
            .build()
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }

    companion object {
        const val ACTION_STOP = "com.aetherride.STOP_RIDE_LOCATION"
        const val ACTION_PAUSE = "com.aetherride.RIDE_PAUSE"
        const val ACTION_MUTE = "com.aetherride.RIDE_MUTE"
        const val ACTION_UPDATE_UI = "com.aetherride.RIDE_UPDATE_NOTIF"
        const val EXTRA_PAUSED = "paused"
        const val EXTRA_MUTED = "muted"
        const val EXTRA_TEXT = "text"
        private const val CHANNEL_ID = "aetherride_ride_location"
        private const val NOTIF_ID = 42
        private const val DEFAULT_TEXT = "Fahrt läuft"

        @JvmStatic
        var eventSink: EventChannel.EventSink? = null

        @JvmStatic
        var actionSink: EventChannel.EventSink? = null

        @Volatile
        private var paused: Boolean = false

        @Volatile
        private var muted: Boolean = false

        @Volatile
        private var contentText: String = DEFAULT_TEXT

        fun start(context: Context) {
            paused = false
            muted = false
            contentText = DEFAULT_TEXT
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

        fun updateUi(
            context: Context,
            paused: Boolean,
            muted: Boolean,
            text: String? = null,
        ) {
            val i = Intent(context, RideLocationService::class.java).apply {
                action = ACTION_UPDATE_UI
                putExtra(EXTRA_PAUSED, paused)
                putExtra(EXTRA_MUTED, muted)
                if (text != null) putExtra(EXTRA_TEXT, text)
            }
            context.startService(i)
        }
    }
}
