package com.zigmdm.agent

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

data class EnrollResult(val deviceId: Long, val uuid: String)
data class Command(val id: Long, val type: String, val payload: String?)
data class Policy(val id: Long, val name: String, val config: JSONObject)
data class PollResult(val deviceId: Long, val commands: List<Command>, val policy: Policy?)

class ApiClient(var baseUrl: String) {
    private val client = OkHttpClient.Builder().connectTimeout(15, TimeUnit.SECONDS).readTimeout(30, TimeUnit.SECONDS).build()
    private val json = "application/json; charset=utf-8".toMediaType()

    private fun post(path: String, body: JSONObject): JSONObject {
        val req = Request.Builder().url(baseUrl.trimEnd('/') + path).post(body.toString().toRequestBody(json)).build()
        client.newCall(req).execute().use { resp ->
            val text = resp.body?.string().orEmpty()
            if (!resp.isSuccessful) throw RuntimeException("HTTP ${resp.code}: $text")
            return JSONObject(text)
        }
    }

    fun enroll(token: String, uuid: String, name: String, model: String, agentVersion: String = "0.1.0-android"): EnrollResult {
        val res = post("/api/agent/enroll", JSONObject()
            .put("token", token).put("uuid", uuid).put("name", name).put("model", model)
            .put("platform", "android").put("agent_version", agentVersion))
        if (!res.optBoolean("ok", false)) throw RuntimeException("enroll failed: $res")
        return EnrollResult(res.getLong("device_id"), res.getString("uuid"))
    }

    fun poll(uuid: String, batteryPct: Int?, extras: JSONObject? = null, agentVersion: String = "0.1.0-android"): PollResult {
        val body = JSONObject().put("uuid", uuid).put("agent_version", agentVersion)
        if (batteryPct != null) body.put("battery_pct", batteryPct)
        if (extras != null && extras.length() > 0) body.put("extras", extras)
        val res = post("/api/agent/poll", body)
        if (!res.optBoolean("ok", false)) throw RuntimeException("poll failed: $res")
        val cmds = mutableListOf<Command>()
        val arr: JSONArray = res.optJSONArray("commands") ?: JSONArray()
        for (i in 0 until arr.length()) {
            val c = arr.getJSONObject(i)
            cmds.add(Command(c.getLong("id"), c.getString("type"), if (c.isNull("payload")) null else c.get("payload").toString()))
        }
        var policy: Policy? = null
        val p = res.optJSONObject("policy")
        if (p != null && p.has("id") && p.getLong("id") > 0) {
            val cfg = p.opt("config")
            val cfgObj = when (cfg) { is JSONObject -> cfg; is String -> JSONObject(cfg); else -> JSONObject() }
            policy = Policy(p.getLong("id"), p.optString("name"), cfgObj)
        }
        return PollResult(res.getLong("device_id"), cmds, policy)
    }

    fun ack(uuid: String, commandId: Long, result: JSONObject) {
        val res = post("/api/agent/ack", JSONObject().put("uuid", uuid).put("command_id", commandId).put("result", result))
        if (!res.optBoolean("ok", false)) throw RuntimeException("ack failed: $res")
    }
}
