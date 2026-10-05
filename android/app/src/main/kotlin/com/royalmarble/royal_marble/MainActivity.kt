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
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    companion object {
        const val ALERTS_CHANNEL = "alerts"
    }
}
