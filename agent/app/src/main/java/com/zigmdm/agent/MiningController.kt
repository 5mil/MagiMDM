package com.zigmdm.agent

import android.content.Context
import android.util.Log
import org.json.JSONObject

object MiningController {
    private const val TAG = "ZigMdmMine"
    private const val PREFS = "zigmdm"

    fun apply(context: Context, policyConfig: JSONObject) {
        val mining = policyConfig.optJSONObject("mining") ?: JSONObject()
        val enabled = mining.optBoolean("enabled", false)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!enabled) {
            prefs.edit().putBoolean("mining_enabled", false).putString("mining_url", "").apply()
            return
        }
        prefs.edit()
            .putBoolean("mining_enabled", true)
            .putString("mining_url", mining.optString("stratum_url", "stratum+tcp://127.0.0.1:3333"))
            .putString("mining_algo", mining.optString("algo", "skein"))
            .putInt("mining_cpu", mining.optInt("max_cpu_pct", 25))
            .putInt("mining_duration_s", mining.optInt("duration_s", 0))
            .putInt("mining_threads", mining.optInt("threads", 1))
            .putInt("mining_report_s", mining.optInt("report_interval_s", 15))
            .apply()
        Log.i(TAG, "Mining allowed (hasher not bundled)")
    }

    fun extras(context: Context): JSONObject {
        val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return JSONObject()
            .put("mining_enabled", p.getBoolean("mining_enabled", false))
            .put("mining_algo", p.getString("mining_algo", ""))
            .put("mining_url", p.getString("mining_url", ""))
            .put("threads", p.getInt("mining_threads", 1))
            .put("duration_s", p.getInt("mining_duration_s", 0))
            .put("report_interval_s", p.getInt("mining_report_s", 15))
            .put("shares", 0)
            .put("rejected", 0)
    }
}
