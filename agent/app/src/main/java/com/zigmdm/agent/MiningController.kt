package com.zigmdm.agent

import android.content.Context
import android.util.Log
import org.json.JSONObject

/** Policy-gated mining. Off unless mining.enabled is true. No hasher shipped. */
object MiningController {
    private const val TAG = "ZigMdmMine"
    private const val PREFS = "zigmdm"

    fun apply(context: Context, policyConfig: JSONObject) {
        val mining = policyConfig.optJSONObject("mining") ?: JSONObject()
        val enabled = mining.optBoolean("enabled", false)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val was = prefs.getBoolean("mining_enabled", false)
        if (!enabled) {
            if (was) Log.i(TAG, "Mining disabled by policy — stop")
            prefs.edit().putBoolean("mining_enabled", false).putString("mining_url", "").apply()
            return
        }
        val url = mining.optString("stratum_url", "stratum+tcp://127.0.0.1:3333")
        val algo = mining.optString("algo", "skein")
        val cpu = mining.optInt("max_cpu_pct", 25)
        prefs.edit()
            .putBoolean("mining_enabled", true)
            .putString("mining_url", url)
            .putString("mining_algo", algo)
            .putInt("mining_cpu", cpu)
            .apply()
        Log.i(TAG, "Mining allowed url=$url algo=$algo cpu=$cpu% (hasher not bundled)")
    }

    fun extras(context: Context): JSONObject {
        val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return JSONObject()
            .put("mining_enabled", p.getBoolean("mining_enabled", false))
            .put("mining_algo", p.getString("mining_algo", ""))
            .put("mining_url", p.getString("mining_url", ""))
    }
}
