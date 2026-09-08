package com.zigmdm.agent

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object CommsLog {
    private const val PREF = "comms_logq"

    fun add(ctx: Context, direction: String, kind: String, peer: String, allowed: Boolean, body: String? = null) {
        val mode = ctx.getSharedPreferences("comms", Context.MODE_PRIVATE).getString("logging", "metadata") ?: "metadata"
        if (mode == "off") return
        if (mode == "deny_only" && allowed) return
        val ev = JSONObject()
            .put("ts", System.currentTimeMillis())
            .put("direction", direction)
            .put("kind", kind)
            .put("peer", CommsPolicy.digits(peer))
            .put("allowed", allowed)
        if (mode == "sms_body" && body != null) ev.put("body", body)
        else if (body != null) ev.put("meta", JSONObject().put("len", body.length))
        val p = ctx.getSharedPreferences(PREF, Context.MODE_PRIVATE)
        val arr = JSONArray(p.getString("q", "[]"))
        arr.put(ev)
        p.edit().putString("q", arr.toString()).apply()
    }

    fun drainJson(ctx: Context): JSONArray {
        val p = ctx.getSharedPreferences(PREF, Context.MODE_PRIVATE)
        val arr = JSONArray(p.getString("q", "[]"))
        p.edit().putString("q", "[]").apply()
        return arr
    }
}
