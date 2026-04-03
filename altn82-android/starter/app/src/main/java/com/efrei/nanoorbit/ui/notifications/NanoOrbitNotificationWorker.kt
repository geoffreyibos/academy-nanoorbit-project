package com.efrei.nanoorbit.ui.notifications

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.efrei.nanoorbit.data.db.NanoOrbitDatabase
import com.efrei.nanoorbit.data.repository.NanoOrbitRepository
import java.time.Duration
import java.time.LocalDateTime

class NanoOrbitNotificationWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        createChannel()
        val repository = NanoOrbitRepository(
            satelliteDao = NanoOrbitDatabase.getInstance(applicationContext).satelliteDao(),
            fenetreDao = NanoOrbitDatabase.getInstance(applicationContext).fenetreDao()
        )
        val payload = repository.getFenetresCacheFirst()
        val upcoming = payload.data.firstOrNull {
            Duration.between(LocalDateTime.now(), it.datetimeDebut).toMinutes() in 0..15
        } ?: return Result.success()

        if (ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return Result.success()
        }

        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Passage imminent")
            .setContentText("${upcoming.idSatellite} - ${upcoming.codeStation} dans moins de 15 min (${upcoming.dureeSecondes}s)")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        NotificationManagerCompat.from(applicationContext).notify(upcoming.idFenetre, notification)
        return Result.success()
    }

    private fun createChannel() {
        val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "NanoOrbit Alerts", NotificationManager.IMPORTANCE_HIGH)
        )
    }

    companion object {
        const val WORK_NAME = "nanoorbit_notifications"
        private const val CHANNEL_ID = "nanoorbit_channel"
    }
}
