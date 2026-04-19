import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stub data model — replace with real persistence layer later
// ─────────────────────────────────────────────────────────────────────────────

class _LimiterProfile {
  final String name;
  final String modelLabel;
  final String timeRange;
  final List<String> apps;
  bool active;

  _LimiterProfile({
    required this.name,
    required this.modelLabel,
    required this.timeRange,
    required this.apps,
    this.active = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class LimiterListPage extends StatefulWidget {
  const LimiterListPage({super.key});

  @override
  State<LimiterListPage> createState() => _LimiterListPageState();
}

class _LimiterListPageState extends State<LimiterListPage> {
  // Stub profiles — will eventually be loaded from storage
  final List<_LimiterProfile> _profiles = [
    _LimiterProfile(
      name: 'Evening Wind-Down',
      modelLabel: 'Shared Hourly',
      timeRange: '7:00 PM – 10:00 PM',
      apps: ['YouTube', 'TikTok', 'Instagram'],
      active: false,
    ),
    _LimiterProfile(
      name: 'Study Hours',
      modelLabel: 'Block Limiter',
      timeRange: '3:00 PM – 6:00 PM',
      apps: ['Reddit', 'Twitter / X'],
      active: false,
    ),
    _LimiterProfile(
      name: 'Social Media Cap',
      modelLabel: 'Per-App Hourly',
      timeRange: 'All Day',
      apps: ['Instagram', 'Snapchat', 'Twitter / X'],
      active: false,
    ),
  ];

  Color _modelColor(String model) {
    switch (model) {
      case 'Shared Hourly':
        return const Color(0xFF3D5AFE);
      case 'Per-App Hourly':
        return const Color(0xFF6C63FF);
      case 'Block Limiter':
        return const Color(0xFFFF6B35);
      default:
        return Colors.grey;
    }
  }

  IconData _modelIcon(String model) {
    switch (model) {
      case 'Shared Hourly':
        return Icons.pie_chart_outline_rounded;
      case 'Per-App Hourly':
        return Icons.apps_rounded;
      case 'Block Limiter':
        return Icons.timer_outlined;
      default:
        return Icons.help_outline;
    }
  }

  void _toggleActive(int index) {
    setState(() {
      _profiles[index].active = !_profiles[index].active;
    });
  }

  Widget _profileCard(_LimiterProfile profile, int index) {
    final color = _modelColor(profile.modelLabel);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: profile.active ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_modelIcon(profile.modelLabel),
                      color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.modelLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Active toggle
                Switch(
                  value: profile.active,
                  activeColor: color,
                  onChanged: (_) => _toggleActive(index),
                ),
              ],
            ),
          ),

          // ── Detail row ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    color: Colors.white.withOpacity(0.35), size: 14),
                const SizedBox(width: 6),
                Text(
                  profile.timeRange,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 18),
                Icon(Icons.phone_android,
                    color: Colors.white.withOpacity(0.35), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    profile.apps.join(', '),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _profiles.where((p) => p.active).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D35),
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Saved Limiters',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status bar ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: activeCount > 0
                      ? const Color(0xFF00B686).withOpacity(0.12)
                      : const Color(0xFF1A1D35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeCount > 0
                        ? const Color(0xFF00B686).withOpacity(0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      activeCount > 0
                          ? Icons.shield_rounded
                          : Icons.shield_outlined,
                      color: activeCount > 0
                          ? const Color(0xFF00B686)
                          : Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      activeCount > 0
                          ? '$activeCount limiter${activeCount > 1 ? 's' : ''} currently active'
                          : 'No limiters active — toggle one below',
                      style: TextStyle(
                        color: activeCount > 0
                            ? const Color(0xFF00B686)
                            : Colors.white38,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Profile list ────────────────────────────────────────────────
              Expanded(
                child: _profiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded,
                                color: Colors.white.withOpacity(0.2),
                                size: 56),
                            const SizedBox(height: 12),
                            Text(
                              'No limiters saved yet.\nTap "New Limiter" on the home screen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _profiles.length,
                        itemBuilder: (_, i) =>
                            _profileCard(_profiles[i], i),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}