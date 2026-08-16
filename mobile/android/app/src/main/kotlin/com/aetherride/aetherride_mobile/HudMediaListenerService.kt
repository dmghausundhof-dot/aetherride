package com.aetherride.aetherride_mobile

import android.service.notification.NotificationListenerService

/**
 * Unlocks [android.media.session.MediaSessionManager.getActiveSessions] for the
 * Ride HUD media chip. Does **not** read notification contents or extras.
 */
class HudMediaListenerService : NotificationListenerService()
