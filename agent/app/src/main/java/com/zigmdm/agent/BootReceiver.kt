package com.zigmdm.agent

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/** After reboot, resume background polling if enrolled. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) return
        val prefs = context.getSharedPreferences("zigmdm", Context.MODE_PRIVATE)
        if (prefs.getString("uuid", null) != null) {
            Log.i("ZigMdmBoot", "Enrolled — scheduling WorkManager poll")
            PollWorker.schedule(context)
        }
    }
}
