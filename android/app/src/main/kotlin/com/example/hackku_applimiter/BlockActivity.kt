package com.example.hackku_applimiter

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Color
import android.view.Gravity

class BlockActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // A fast, brutalist UI created entirely in code (no XML needed for MVP)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0F1120"))
        }

        val title = TextView(this).apply {
            text = "APP BLOCKED"
            textSize = 32f
            setTextColor(Color.parseColor("#FF4D4D"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }

        val subtitle = TextView(this).apply {
            text = "You have exceeded your time budget for this app."
            textSize = 16f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 64)
        }

        val homeButton = Button(this).apply {
            text = "Return to Home"
            setBackgroundColor(Color.parseColor("#3D5AFE"))
            setTextColor(Color.WHITE)
            setOnClickListener {
                // Kick them back to the launcher
                val homeIntent = Intent(Intent.ACTION_MAIN)
                homeIntent.addCategory(Intent.CATEGORY_HOME)
                homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(homeIntent)
                finish()
            }
        }

        layout.addView(title)
        layout.addView(subtitle)
        layout.addView(homeButton)

        setContentView(layout)
    }

    // Prevent bypassing via the back button
    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        // Do nothing. They are trapped.
    }
}