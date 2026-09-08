package com.zigmdm.parent

import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.net.HttpURLConnection
import java.net.URL

data class DeviceRow(
    val id: Int,
    val name: String,
    val platform: String,
    val status: String,
    val lastSeen: String,
    val policy: String,
)

class Api(private val base: String, var cookie: String? = null) {
    fun login(user: String, pass: String): Boolean {
        val body = "username=${enc(user)}&password=${enc(pass)}"
        val conn = open("/login", "POST", body, form = true)
        cookie = conn.headerFields["Set-Cookie"]?.joinToString(";")
        val code = conn.responseCode
        conn.disconnect()
        return code in 200..399
    }

    fun devices(): List<DeviceRow> {
        val raw = get("/api/parent/devices")
        val arr = JSONObject(raw).optJSONArray("devices") ?: JSONArray()
        val out = mutableListOf<DeviceRow>()
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            out.add(
                DeviceRow(
                    o.optInt("id"),
                    o.optString("name", "device"),
                    o.optString("platform", "?"),
                    o.optString("status", ""),
                    o.optString("last_seen_at", "—"),
                    o.optString("policy", ""),
                ),
            )
        }
        return out
    }

    fun bulkPolicy(name: String) {
        open("/devices/bulk", "POST", "policy=${enc(name)}", form = true).disconnect()
    }

    fun bulkLock() {
        open("/devices/bulk", "POST", "command=lock", form = true).disconnect()
    }

    private fun get(path: String): String {
        val conn = open(path, "GET", null, form = false)
        val text = conn.inputStream.bufferedReader().use(BufferedReader::readText)
        conn.disconnect()
        return text
    }

    private fun open(path: String, method: String, body: String?, form: Boolean): HttpURLConnection {
        val conn = URL(base.trimEnd('/') + path).openConnection() as HttpURLConnection
        conn.requestMethod = method
        conn.connectTimeout = 8000
        conn.readTimeout = 8000
        conn.instanceFollowRedirects = true
        cookie?.let { conn.setRequestProperty("Cookie", it) }
        if (body != null) {
            conn.doOutput = true
            conn.setRequestProperty(
                "Content-Type",
                if (form) "application/x-www-form-urlencoded" else "application/json",
            )
            conn.outputStream.use { it.write(body.toByteArray()) }
        }
        return conn
    }

    private fun enc(s: String) = java.net.URLEncoder.encode(s, "UTF-8")
}
