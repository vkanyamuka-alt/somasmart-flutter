package com.example.somasmart_flutter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    /**
     * Push messages name one of these channels (Edge Functions push-send and
     * push-reminders). Students can mute each one in Android's app settings.
     * Creating an existing channel again only refreshes its name (language).
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel(
                "study_reminders",
                getString(R.string.channel_study_reminders),
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply { description = getString(R.string.channel_study_reminders_description) },
        )
        manager.createNotificationChannel(
            NotificationChannel(
                "announcements",
                getString(R.string.channel_announcements),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = getString(R.string.channel_announcements_description) },
        )
    }
}
