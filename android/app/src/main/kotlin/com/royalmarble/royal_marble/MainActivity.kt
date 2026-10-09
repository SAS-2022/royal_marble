package com.royalmarble.tracking

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAlertsChannel()
    }

    /** High importance so worker alerts pop up; FCM uses it by default (see the manifest). */
    private fun createAlertsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(ALERTS_CHANNEL, "Alerts", NotificationManager.IMPORTANCE_HIGH)
        channel.description = "Workers leaving a site, phone problems and new sign-ups"
        val quiet = NotificationChannel(QUIET_CHANNEL, "Quiet hours", NotificationManager.IMPORTANCE_LOW)
        quiet.description = "Alerts during your quiet hours: no sound or pop-up"
        getSystemService(NotificationManager::class.java).createNotificationChannels(listOf(channel, quiet))
    }

    companion object {
        const val ALERTS_CHANNEL = "alerts"
        const val QUIET_CHANNEL = "quiet"
    }
}
