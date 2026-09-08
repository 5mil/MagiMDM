package com.zigmdm.agent

import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log

class CallGateService : CallScreeningService() {
    override fun onScreenCall(details: Call.Details) {
        val handle = details.handle?.schemeSpecificPart ?: ""
        val incoming = details.callDirection != Call.Details.DIRECTION_OUTGOING
        val dir = if (incoming) "in" else "out"
        val ok = CommsPolicy.allowed(this, handle, dir)
        CommsLog.add(this, dir, "call", handle, ok)
        val resp = CallResponse.Builder()
        if (!ok) {
            resp.setRejectCall(true).setDisallowCall(true).setSkipCallLog(false).setSkipNotification(true)
            Log.i("CallGate", "reject $dir $handle")
        }
        respondToCall(details, resp.build())
    }
}
