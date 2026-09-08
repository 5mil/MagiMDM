package com.zigmdm.agent

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.UserManager
import org.json.JSONObject

object CommsPolicy {
    private const val PREF = "comms"
    val EMERGENCY = setOf("911", "112", "000", "110", "119", "999")

    fun apply(ctx: Context, cfg: JSONObject, dpm: DevicePolicyManager, admin: ComponentName, owner: Boolean) {
        val comms = cfg.optJSONObject("comms") ?: JSONObject()
        val prefs = ctx.getSharedPreferences(PREF, Context.MODE_PRIVATE)
        val nums = comms.optJSONArray("allow_numbers")
        val buf = StringBuilder()
        if (nums != null) {
            for (i in 0 until nums.length()) {
                if (i > 0) buf.append(',')
                buf.append(digits(nums.optString(i)))
            }
        }
        prefs.edit()
            .putString("allow", buf.toString())
            .putString("incoming", comms.optString("incoming", "allowlist"))
            .putString("outgoing", comms.optString("outgoing_calls", "allowlist"))
            .putString("sms", comms.optString("sms", "allowlist"))
            .putString("logging", comms.optString("logging", "metadata"))
            .putBoolean("emergency", comms.optBoolean("emergency_always", true))
            .apply()
        if (!owner) return
        val out = comms.optString("outgoing_calls", "allowlist")
        val sms = comms.optString("sms", "allowlist")
        if (out == "block_all") dpm.addUserRestriction(admin, UserManager.DISALLOW_OUTGOING_CALLS)
        else dpm.clearUserRestriction(admin, UserManager.DISALLOW_OUTGOING_CALLS)
        if (sms == "block_all") dpm.addUserRestriction(admin, UserManager.DISALLOW_SMS)
        else dpm.clearUserRestriction(admin, UserManager.DISALLOW_SMS)
    }

    fun allowed(ctx: Context, raw: String, direction: String): Boolean {
        val n = digits(raw)
        if (n.isEmpty()) return false
        val p = ctx.getSharedPreferences(PREF, Context.MODE_PRIVATE)
        if (p.getBoolean("emergency", true) && EMERGENCY.contains(n)) return true
        val mode = when (direction) {
            "in" -> p.getString("incoming", "allowlist")
            "sms" -> p.getString("sms", "allowlist")
            else -> p.getString("outgoing", "allowlist")
        }
        if (mode == "open") return true
        if (mode == "block_all") return false
        val allow = p.getString("allow", "") ?: ""
        if (allow.isEmpty()) return false
        return allow.split(',').any { it.isNotEmpty() && (n.endsWith(it) || it.endsWith(n)) }
    }

    fun digits(s: String): String = s.filter { it.isDigit() }
}
