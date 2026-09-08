package com.zigmdm.agent

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.UserManager
import android.util.Log
import org.json.JSONObject

class CommandExecutor(private val context: Context) {
    private val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val admin = ComponentName(context, MdmDeviceAdminReceiver::class.java)
    private val isOwner: Boolean get() = dpm.isDeviceOwnerApp(context.packageName)

    fun execute(cmd: Command): JSONObject {
        Log.i(TAG, "Execute ${cmd.type} id=${cmd.id} owner=$isOwner")
        return when (cmd.type) {
            "lock" -> lock()
            "reboot" -> reboot()
            "wipe" -> wipe()
            "deploy_apk" -> deployApk(cmd)
            "applyPolicy" -> {
                applyPolicyJson(cmd.payload)
                JSONObject().put("status", "ok").put("type", "applyPolicy")
            }
            else -> JSONObject().put("status", "ignored").put("type", cmd.type)
        }
    }

    fun applyPolicy(policy: Policy) {
        applyPolicyJson(policy.config.toString())
    }

    fun applyPolicyJson(raw: String?) {
        val cfg = try { if (raw != null) JSONObject(raw) else JSONObject() } catch (_: Exception) { JSONObject() }
        MiningController.apply(context, cfg)
        CommsPolicy.apply(context, cfg, dpm, admin, isOwner)
        val mode = cfg.optString("mode", Schedule.pickMode())
        if (!isOwner) {
            Log.w(TAG, "Not device owner — DPC skipped; mode=$mode")
            return
        }
        if (cfg.has("camera")) {
            dpm.setCameraDisabled(admin, !cfg.optBoolean("camera", true))
        }
        val lockInstall = cfg.optBoolean("install_lock", mode == "school" || mode == "exam")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (lockInstall) {
                dpm.addUserRestriction(admin, UserManager.DISALLOW_INSTALL_UNKNOWN_SOURCES)
            } else {
                dpm.clearUserRestriction(admin, UserManager.DISALLOW_INSTALL_UNKNOWN_SOURCES)
            }
        }
    }

    private fun lock(): JSONObject {
        if (isOwner) { dpm.lockNow(); return JSONObject().put("status", "ok").put("type", "lock") }
        return JSONObject().put("status", "simulated").put("type", "lock")
    }
    private fun reboot(): JSONObject {
        if (isOwner && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            dpm.reboot(admin)
            return JSONObject().put("status", "ok").put("type", "reboot")
        }
        return JSONObject().put("status", "simulated").put("type", "reboot")
    }
    private fun wipe(): JSONObject {
        return JSONObject().put("status", if (isOwner) "refused_scaffold" else "simulated").put("type", "wipe")
    }
    private fun deployApk(cmd: Command): JSONObject {
        val payload = try { if (cmd.payload != null) JSONObject(cmd.payload) else JSONObject() } catch (_: Exception) { JSONObject() }
        return JSONObject().put("status", "simulated").put("type", "deploy_apk").put("url", payload.optString("url", ""))
    }
    companion object { private const val TAG = "ZigMdmExec" }
}
