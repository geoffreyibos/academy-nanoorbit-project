package com.efrei.nanoorbit

import android.app.Application
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.efrei.nanoorbit.ui.notifications.NanoOrbitNotificationWorker
import org.osmdroid.config.Configuration
import java.util.concurrent.TimeUnit

class NanoOrbitApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Configuration.getInstance().userAgentValue = packageName
        scheduleNotificationWorker()
    }

    private fun scheduleNotificationWorker() {
        val request = PeriodicWorkRequestBuilder<NanoOrbitNotificationWorker>(15, TimeUnit.MINUTES)
            .build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            NanoOrbitNotificationWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request
        )
    }
}
