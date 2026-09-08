package com.zigmdm.parent

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import kotlin.concurrent.thread

class LoginActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)
        findViewById<Button>(R.id.btn).setOnClickListener {
            val url = findViewById<EditText>(R.id.url).text.toString()
            val user = findViewById<EditText>(R.id.user).text.toString()
            val pass = findViewById<EditText>(R.id.pass).text.toString()
            thread {
                val api = Api(url)
                val ok = runCatching { api.login(user, pass) }.getOrDefault(false)
                runOnUiThread {
                    if (!ok) {
                        Toast.makeText(this, "Login failed", Toast.LENGTH_SHORT).show()
                    } else {
                        Session.api = api
                        startActivity(Intent(this, HomeActivity::class.java))
                        finish()
                    }
                }
            }
        }
    }
}

object Session { var api: Api? = null }
