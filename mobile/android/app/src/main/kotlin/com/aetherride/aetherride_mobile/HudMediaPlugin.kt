package com.aetherride.aetherride_mobile

import android.app.Activity
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.view.KeyEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Generic now-playing + transport for the Ride HUD (Spotify, YT Music, …).
 * Uses MediaSession when the notification listener is granted; otherwise
 * [AudioManager.isMusicActive] + media keys.
 */
class HudMediaPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, ActivityAware {

    private lateinit var methods: MethodChannel
    private lateinit var events: EventChannel
    private val mainHandler = Handler(Looper.getMainLooper())

    private var appContext: Context? = null
    private var activity: Activity? = null
    private var sink: EventChannel.EventSink? = null
    private var watching = false
    private var mediaSessionManager: MediaSessionManager? = null
    private var audioManager: AudioManager? = null
    private var controller: MediaController? = null
    private var sessionsListener: MediaSessionManager.OnActiveSessionsChangedListener? =
        null

    private val poll = object : Runnable {
        override fun run() {
            if (!watching) return
            ensureSessionListener()
            bindController(null)
            emit()
            mainHandler.postDelayed(this, POLL_MS)
        }
    }

    private val controllerCallback = object : MediaController.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadata?) {
            emit()
        }

        override fun onPlaybackStateChanged(state: PlaybackState?) {
            emit()
        }

        override fun onSessionDestroyed() {
            controller = null
            bindController(null)
            emit()
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        mediaSessionManager =
            binding.applicationContext.getSystemService(MediaSessionManager::class.java)
        audioManager =
            binding.applicationContext.getSystemService(AudioManager::class.java)
        methods = MethodChannel(binding.binaryMessenger, CHANNEL)
        events = EventChannel(binding.binaryMessenger, EVENTS)
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopWatching()
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        appContext = null
        mediaSessionManager = null
        audioManager = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        emit()
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isListenerEnabled" -> result.success(isListenerEnabled())
            "openListenerSettings" -> {
                openListenerSettings()
                result.success(true)
            }
            "start" -> {
                startWatching()
                result.success(snapshot())
            }
            "stop" -> {
                stopWatching()
                result.success(true)
            }
            "nowPlaying" -> result.success(snapshot())
            "playPause" -> {
                playPause()
                result.success(true)
            }
            "skipNext" -> {
                skip(next = true)
                result.success(true)
            }
            "skipPrevious" -> {
                skip(next = false)
                result.success(true)
            }
            "openPlayer" -> {
                openPlayer()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun startWatching() {
        if (watching) {
            ensureSessionListener()
            bindController(null)
            emit()
            return
        }
        watching = true
        ensureSessionListener()
        bindController(null)
        emit()
        mainHandler.removeCallbacks(poll)
        mainHandler.postDelayed(poll, POLL_MS)
    }

    private fun ensureSessionListener() {
        if (sessionsListener != null) return
        val msm = mediaSessionManager ?: return
        if (!isListenerEnabled()) return
        val listener = MediaSessionManager.OnActiveSessionsChangedListener { list ->
            mainHandler.post {
                bindController(list)
                emit()
            }
        }
        sessionsListener = listener
        try {
            msm.addOnActiveSessionsChangedListener(listener, listenerComponent())
        } catch (_: SecurityException) {
            sessionsListener = null
        }
    }

    private fun stopWatching() {
        watching = false
        mainHandler.removeCallbacks(poll)
        dropSessionListener()
        try {
            controller?.unregisterCallback(controllerCallback)
        } catch (_: Exception) {
        }
        controller = null
    }

    private fun dropSessionListener() {
        val msm = mediaSessionManager
        val listener = sessionsListener
        sessionsListener = null
        if (msm == null || listener == null) return
        try {
            msm.removeOnActiveSessionsChangedListener(listener)
        } catch (_: Exception) {
        }
    }

    private fun bindController(sessions: List<MediaController>?) {
        val ctx = appContext ?: return
        val list = try {
            sessions ?: mediaSessionManager?.getActiveSessions(listenerComponent())
                ?: emptyList()
        } catch (_: SecurityException) {
            // Grant revoked (or listener not bound yet). Drop so the poll
            // can re-register after the user re-enables access.
            dropSessionListener()
            emptyList()
        }
        val ours = ctx.packageName
        val candidates = list.filter { it.packageName != ours }
        val playing = candidates.firstOrNull {
            it.playbackState?.state == PlaybackState.STATE_PLAYING
        }
        val chosen = playing
            ?: candidates.maxByOrNull { it.playbackState?.lastPositionUpdateTime ?: 0L }

        val current = controller
        if (chosen != null &&
            current != null &&
            chosen.sessionToken == current.sessionToken
        ) {
            return
        }
        try {
            current?.unregisterCallback(controllerCallback)
        } catch (_: Exception) {
        }
        controller = chosen
        try {
            chosen?.registerCallback(controllerCallback, mainHandler)
        } catch (_: Exception) {
            controller = null
        }
    }

    private fun playPause() {
        val c = controller
        val state = c?.playbackState?.state
        if (c != null) {
            if (state == PlaybackState.STATE_PLAYING) {
                c.transportControls.pause()
            } else {
                c.transportControls.play()
            }
        } else {
            dispatchMediaKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
        }
        mainHandler.postDelayed({ emit() }, 200)
    }

    private fun skip(next: Boolean) {
        val c = controller
        if (c != null) {
            if (next) c.transportControls.skipToNext()
            else c.transportControls.skipToPrevious()
        } else {
            dispatchMediaKey(
                if (next) KeyEvent.KEYCODE_MEDIA_NEXT
                else KeyEvent.KEYCODE_MEDIA_PREVIOUS,
            )
        }
        mainHandler.postDelayed({ emit() }, 280)
    }

    private fun dispatchMediaKey(code: Int) {
        val am = audioManager ?: return
        val now = SystemClock.uptimeMillis()
        am.dispatchMediaKeyEvent(KeyEvent(now, now, KeyEvent.ACTION_DOWN, code, 0))
        am.dispatchMediaKeyEvent(KeyEvent(now, now, KeyEvent.ACTION_UP, code, 0))
    }

    private fun openListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        val act = activity
        if (act != null) {
            act.startActivity(intent)
        } else {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            appContext?.startActivity(intent)
        }
    }

    private fun openPlayer() {
        val pkg = controller?.packageName ?: return
        val ctx = appContext ?: return
        val launch = ctx.packageManager.getLaunchIntentForPackage(pkg) ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val act = activity
        if (act != null) act.startActivity(launch) else ctx.startActivity(launch)
    }

    private fun emit() {
        val payload = snapshot()
        val s = sink
        if (s == null) return
        if (Looper.myLooper() == Looper.getMainLooper()) {
            s.success(payload)
        } else {
            mainHandler.post { sink?.success(payload) }
        }
    }

    private fun snapshot(): Map<String, Any?> {
        val c = controller
        val meta = c?.metadata
        val state = c?.playbackState
        val actions = state?.actions ?: 0L
        val advertised = actions != 0L
        val title = firstNonBlank(
            meta?.getString(MediaMetadata.METADATA_KEY_TITLE),
            meta?.getString(MediaMetadata.METADATA_KEY_DISPLAY_TITLE),
        )
        val artist = firstNonBlank(
            meta?.getString(MediaMetadata.METADATA_KEY_ARTIST),
            meta?.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST),
            meta?.getString(MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE),
        )
        @Suppress("DEPRECATION")
        val musicActive = audioManager?.isMusicActive == true
        return hashMapOf(
            "listenerEnabled" to isListenerEnabled(),
            "musicActive" to musicActive,
            "active" to (c != null),
            "playing" to (state?.state == PlaybackState.STATE_PLAYING ||
                (c == null && musicActive)),
            "title" to title,
            "artist" to artist,
            "appLabel" to labelFor(c?.packageName),
            "packageName" to (c?.packageName ?: ""),
            "canSkipNext" to (
                !advertised ||
                    (actions and PlaybackState.ACTION_SKIP_TO_NEXT) != 0L
                ),
            "canSkipPrevious" to (
                !advertised ||
                    (actions and PlaybackState.ACTION_SKIP_TO_PREVIOUS) != 0L
                ),
        )
    }

    private fun labelFor(packageName: String?): String {
        if (packageName.isNullOrBlank()) return ""
        APP_LABELS[packageName]?.let { return it }
        val ctx = appContext ?: return ""
        return try {
            val pm = ctx.packageManager
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getApplicationInfo(
                    packageName,
                    PackageManager.ApplicationInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                pm.getApplicationInfo(packageName, 0)
            }
            pm.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            APP_LABELS[packageName] ?: ""
        }
    }

    private fun isListenerEnabled(): Boolean {
        val ctx = appContext ?: return false
        val cn = listenerComponent()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val nm = ctx.getSystemService(NotificationManager::class.java)
            nm.isNotificationListenerAccessGranted(cn)
        } else {
            val flat = Settings.Secure.getString(
                ctx.contentResolver,
                "enabled_notification_listeners",
            ) ?: return false
            flat.split(':').any {
                it.contains(ctx.packageName, ignoreCase = true)
            }
        }
    }

    private fun listenerComponent(): ComponentName {
        return ComponentName(
            appContext ?: activity ?: error("no context"),
            HudMediaListenerService::class.java,
        )
    }

    private fun firstNonBlank(vararg values: String?): String {
        for (v in values) {
            if (!v.isNullOrBlank()) return v.trim()
        }
        return ""
    }

    companion object {
        const val CHANNEL = "com.aetherride/hud_media"
        const val EVENTS = "com.aetherride/hud_media/now_playing"
        private const val POLL_MS = 1500L

        private val APP_LABELS = mapOf(
            "com.spotify.music" to "Spotify",
            "com.spotify.lite" to "Spotify",
            "com.google.android.apps.youtube.music" to "YouTube Music",
            "com.google.android.music" to "YT Music",
            "com.apple.android.music" to "Apple Music",
            "com.amazon.mp3" to "Amazon Music",
            "com.soundcloud.android" to "SoundCloud",
            "deezer.android.app" to "Deezer",
            "com.aspiro.tidal" to "TIDAL",
            "org.videolan.vlc" to "VLC",
            "com.google.android.youtube" to "YouTube",
            "au.com.shiftyjelly.pocketcasts" to "Pocket Casts",
            "com.bambuna.podcastaddict" to "Podcast Addict",
            "fm.antennapod.podcast" to "AntennaPod",
            "de.danoeh.antennapod" to "AntennaPod",
        )
    }
}
