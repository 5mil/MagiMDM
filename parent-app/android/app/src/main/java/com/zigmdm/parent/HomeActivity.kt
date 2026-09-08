package com.zigmdm.parent

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import kotlin.concurrent.thread

class HomeActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_home)
        refresh()
        findViewById<Button>(R.id.school).setOnClickListener { act { it.bulkPolicy("SchoolDay") } }
        findViewById<Button>(R.id.free).setOnClickListener { act { it.bulkPolicy("AfterHours") } }
        findViewById<Button>(R.id.exam).setOnClickListener { act { it.bulkPolicy("ExamLock") } }
        findViewById<Button>(R.id.lock).setOnClickListener { act { it.bulkLock() } }
        findViewById<Button>(R.id.refresh).setOnClickListener { refresh() }
    }

    private fun act(block: (Api) -> Unit) {
        val api = Session.api ?: return
        thread {
            runCatching { block(api) }
            runOnUiThread { refresh(); Toast.makeText(this, "Sent", Toast.LENGTH_SHORT).show() }
        }
    }

    private fun refresh() {
        val api = Session.api ?: return
        thread {
            val rows = runCatching { api.devices() }.getOrDefault(emptyList())
            val text = rows.joinToString("\n") { d ->
                "${d.name}  ${d.platform}  ${d.policy}\n  last ${d.lastSeen}  ${d.status}"
            }.ifEmpty { "No devices yet (or /api/parent/devices not wired)." }
            runOnUiThread { findViewById<TextView>(R.id.list).text = text }
        }
    }
}
