package com.songbuddy.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi

object NotificationChannelHelper {
    
    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "currently_playing_sync"
            val channelName = "SongBuddy Sync"
            val channelDescription = "Background sync for currently playing music"
            val importance = NotificationManager.IMPORTANCE_LOW
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}

