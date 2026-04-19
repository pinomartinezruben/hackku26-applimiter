import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED FOR METHOD CHANNEL

// ─────────────────────────────────────────────────────────────────────────────
// More Options / Settings skeleton
// All tiles are placeholders — wire up logic in a later sprint.
// ─────────────────────────────────────────────────────────────────────────────

class MoreOptionsPage extends StatefulWidget {
  const MoreOptionsPage({super.key});

  @override
  State<MoreOptionsPage> createState() => _MoreOptionsPageState();
}

class _MoreOptionsPageState extends State<MoreOptionsPage> {
  // ── Placeholder state ──────────────────────────────────────────────────────
  bool _pinEnabled        = false;
  bool _notifTimerEnabled = true;
  bool _trackingEnabled   = true;

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 8, left: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF3D5AFE),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      );

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    bool comingSoon = false,
  }) {
    return Opacity(
      opacity: comingSoon ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: comingSoon ? null : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: iconColor ?? Colors.white.withOpacity(0.55),
                  size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (comingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SOON',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.38),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
    bool comingSoon = false,
  }) =>
      _settingsTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        iconColor: iconColor,
        comingSoon: comingSoon,
        trailing: Switch(
          value: value,
          activeColor: const Color(0xFF3D5AFE),
          onChanged: comingSoon ? null : onChanged,
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D35),
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'More Options',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Security ───────────────────────────────────────────────────────
          _sectionLabel('SECURITY'),
          _toggleTile(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF3D5AFE),
            title: 'PIN Lock',
            subtitle: _pinEnabled
                ? 'Hard-lock mode — PIN required for all changes'
                : 'Self-discipline mode — settings are freely editable',
            value: _pinEnabled,
            onChanged: (v) {
              setState(() => _pinEnabled = v);
              // TODO: Prompt PIN setup / removal dialog
            },
          ),
          _settingsTile(
            icon: Icons.password_rounded,
            title: 'Change PIN',
            subtitle: 'Update your current PIN',
            iconColor: Colors.white54,
            comingSoon: !_pinEnabled,
            onTap: () {
              // TODO: Navigate to PIN change dialog
            },
            trailing: const Icon(Icons.chevron_right,
                color: Colors.white30, size: 20),
          ),

          // ── Notifications ──────────────────────────────────────────────────
          _sectionLabel('NOTIFICATIONS'),
          _toggleTile(
            icon: Icons.notifications_active_outlined,
            iconColor: const Color(0xFF00B686),
            title: 'Notification Bar Timer',
            subtitle: 'Show remaining time for the active app in the status bar',
            value: _notifTimerEnabled,
            onChanged: (v) => setState(() => _notifTimerEnabled = v),
          ),

          // ── Tracking ───────────────────────────────────────────────────────
          _sectionLabel('USAGE TRACKING'),
          _toggleTile(
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF6C63FF),
            title: 'Track Usage Data',
            subtitle: 'Record time spent per app, even when limits are off',
            value: _trackingEnabled,
            onChanged: (v) => setState(() => _trackingEnabled = v),
          ),
          _settingsTile(
            icon: Icons.history_rounded,
            title: 'View Usage History',
            subtitle: 'See per-app usage logs',
            comingSoon: true,
            trailing: const Icon(Icons.chevron_right,
                color: Colors.white30, size: 20),
          ),

          // ── Danger zone ────────────────────────────────────────────────────
          _sectionLabel('DATA'),
          _settingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: const Color(0xFFFF4D4D),
            title: 'Reset All Limiters',
            subtitle: 'Permanently delete all saved profiles',
            onTap: () {
              // TODO: Confirmation dialog before destructive action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset dialog coming soon.'),
                  backgroundColor: Color(0xFFFF4D4D),
                ),
              );
            },
            trailing: const Icon(Icons.chevron_right,
                color: Colors.white30, size: 20),
          ),

          const SizedBox(height: 32),

          // ── App info footer ────────────────────────────────────────────────
          Center(
            child: Text(
              'AppLimiter · HackKU Build\nSettings are non-functional placeholders',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}