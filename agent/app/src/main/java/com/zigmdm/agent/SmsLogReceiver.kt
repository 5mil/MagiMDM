package com.zigmdm.agent

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/** Logs incoming SMS the system still broadcasts. Default-SMS role is required for a full archive. */
class SmsLogReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        for (msg in Telephony.Sms.Intents.getMessagesFromIntent(intent)) {
            val peer = msg.originatingAddress ?: ""
            val body = msg.messageBody ?: ""
            val ok = CommsPolicy.allowed(context, peer, "sms")
            CommsLog.add(context, "in", "sms", peer, ok, body)
        }
    }
}
