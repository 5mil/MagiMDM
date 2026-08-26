package com.zigmdm.agent

import android.content.Context
import android.os.BatteryManager
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/** Background poll using WorkManager (≥15 min period on modern Android). */
class PollWorker(appContext: Context, params: WorkerParameters) :
    CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences("zigmdm", Context.MODE_PRIVATE)
        val server = prefs.getString("server", null) ?: return Result.success()
        val uuid = prefs.getString("uuid", null) ?: return Result.success()
        return try {
            val api = ApiClient(server)
            val bm = applicationContext.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val battery = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            val poll = api.poll(uuid, battery)
            val exec = CommandExecutor(applicationContext)
            poll.policy?.let { exec.applyPolicy(it) }
            for (cmd in poll.commands) {
                val result = exec.execute(cmd)
                api.ack(uuid, cmd.id, result)
            }
            Log.i(TAG, "Poll ok cmds=${poll.commands.size}")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Poll failed: ${e.message}")
            Result.retry()
        }
    }

    companion object {
        private const val TAG = "ZigMdmPollWorker"
        private const val UNIQUE = "zigmdm-poll"

        fun schedule(context: Context, intervalMinutes: Long = 15) {
            val req = PeriodicWorkRequestBuilder<PollWorker>(
                intervalMinutes.coerceAtLeast(15),
                TimeUnit.MINUTES,
            ).build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE,
                ExistingPeriodicWorkPolicy.UPDATE,
                req,
            )
            Log.i(TAG, "Scheduled periodic poll every ${intervalMinutes.coerceAtLeast(15)} min")
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(UNIQUE)
        }
    }
}
