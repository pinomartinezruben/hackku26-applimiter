package com.example.hackku_applimiter

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

// ─────────────────────────────────────────────────────────────────────────────
//  BlockActivity — The inescapable enforcement screen.
//
//  Why a raw Activity and not a Flutter route?
//  -------------------------------------------
//  When LimiterService fires the blocker intent, Flutter may not be in the
//  foreground. Launching a native Android Activity is the only way to guarantee
//  the block screen appears instantly regardless of the Flutter engine state.
//  Routing to a Flutter page over a MethodChannel requires the engine to be
//  live and responsive — we cannot count on that from a background service.
//
//  Why FLAG_ACTIVITY_CLEAR_TASK?
//  ------------------------------
//  Without it, the restricted app's Activity stack would still exist behind
//  BlockActivity. The user could long-press Recent Apps and swap back. With
//  CLEAR_TASK, the OS destroys the entire task and makes BlockActivity the
//  new root — there is literally nothing to back out to.
//
//  Why override onBackPressed()?
//  ------------------------------
//  Even with CLEAR_TASK, the hardware Back button would pop BlockActivity off
//  the stack (since it's the root, this would go to the home screen — better
//  than the restricted app, but still a form of escape). We suppress it
//  entirely so the only exit is the explicit "Return to Home" button, which
//  navigates via a HOME intent rather than a Back navigation.
//
//  The re-entry trap:
//  ------------------
//  If the user presses the Recent Apps button and taps the restricted app
//  directly, LimiterService's 2-second polling loop will detect that a
//  restricted app is foregrounded (budget still 0), and will re-launch
//  BlockActivity within ≤ 2 seconds, overwriting whatever the user switched to.
//  This creates a tight enforcement loop that requires no Activity-level tricks.
// ─────────────────────────────────────────────────────────────────────────────

class BlockActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ── Root layout ──────────────────────────────────────────────────────
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = Gravity.CENTER
            setPadding(64, 64, 64, 64)
            setBackgroundColor(Color.parseColor("#0F1120"))  // Same dark bg as Flutter UI
        }

        // ── Icon / badge row ─────────────────────────────────────────────────
        // A simple filled circle with an X — no image assets required.
        val iconView = TextView(this).apply {
            text     = "✕"
            textSize = 48f
            setTextColor(Color.parseColor("#FF4D4D"))
            gravity = Gravity.CENTER
            setTypeface(null, Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 32 }
        }

        // ── "APP BLOCKED" headline ───────────────────────────────────────────
        val headline = TextView(this).apply {
            text     = "APP BLOCKED"
            textSize = 32f
            setTextColor(Color.parseColor("#FF4D4D"))
            gravity  = Gravity.CENTER
            setTypeface(null, Typeface.BOLD)
            letterSpacing = 0.15f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 24 }
        }

        // ── Sub-message ──────────────────────────────────────────────────────
        val message = TextView(this).apply {
            text     = "Your time budget for this app has been exhausted.\nThe limit resets at the end of your active window."
            textSize = 15f
            setTextColor(Color.parseColor("#99FFFFFF"))  // 60% white
            gravity  = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 64 }
        }

        // ── Divider ──────────────────────────────────────────────────────────
        val divider = View(this).apply {
            setBackgroundColor(Color.parseColor("#1A1D35"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 2
            ).apply {
                bottomMargin = 64
                leftMargin   = 32
                rightMargin  = 32
            }
        }

        // ── "Return to Home" button ──────────────────────────────────────────
        // This is the ONLY sanctioned exit path. It sends the user to the
        // Android launcher — not back to the restricted app.
        val homeButton = Button(this).apply {
            text    = "Return to Home"
            textSize = 16f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#3D5AFE"))  // Brand blue
            setTypeface(null, Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                128
            ).apply {
                leftMargin  = 32
                rightMargin = 32
            }
            setOnClickListener {
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
                finish()
            }
        }

        root.addView(iconView)
        root.addView(headline)
        root.addView(message)
        root.addView(divider)
        root.addView(homeButton)

        setContentView(root)
    }

    // ── Back button trap ─────────────────────────────────────────────────────
    //
    // Suppressed entirely. The hardware Back button does nothing here.
    // The user's only exit is the "Return to Home" button above.
    //
    // Note on the deprecation: onBackPressed() was deprecated in API 33 in
    // favour of OnBackPressedCallback, but the new API still calls the old one
    // for Activities that don't register a callback, so this suppression is
    // universally effective across all API levels we support.

    @Deprecated("Deprecated in Java")
    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        // Intentionally empty — trap the user.
    }

    // ── Recent Apps trap ─────────────────────────────────────────────────────
    //
    // onUserLeaveHint() fires when the user presses the Home or Recent Apps
    // button. We can't technically prevent them from leaving, but we can
    // immediately re-assert the block screen when they try to return to any
    // restricted app. LimiterService handles that part via its polling loop.
    //
    // We do NOT call finish() here because that would remove BlockActivity from
    // the stack and allow the user to return to their restricted app via recents.
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // No-op. The service handles re-blocking within 2 seconds of any
        // restricted app being foregrounded again.
    }
}