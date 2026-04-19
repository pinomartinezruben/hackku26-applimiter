import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Decoded profile — a strongly-typed view of the JSON config.
// This is what LimiterListPage displays; it is never hardcoded.
// ─────────────────────────────────────────────────────────────────────────────

class LimiterProfile {
  final String model;          // 'sharedHourly' | 'perAppHourly' | 'blockLimiter'
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int sharedBudget;      // minutes; 0 when perAppHourly
  final Map<String, int> perAppBudgets;
  final List<String> packages;
  bool active;                 // UI toggle state — does NOT persist (yet)

  LimiterProfile({
    required this.model,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.sharedBudget,
    required this.perAppBudgets,
    required this.packages,
    this.active = false,
  });

  factory LimiterProfile.fromJson(String jsonString) {
    final m = jsonDecode(jsonString) as Map<String, dynamic>;
    final perAppRaw = m['perAppBudgets'] as Map<String, dynamic>? ?? {};
    return LimiterProfile(
      model:         m['model']           as String,
      startHour:     m['startTimeHour']   as int,
      startMinute:   m['startTimeMinute'] as int,
      endHour:       m['endTimeHour']     as int,
      endMinute:     m['endTimeMinute']   as int,
      sharedBudget:  m['sharedBudget']    as int,
      perAppBudgets: perAppRaw.map((k, v) => MapEntry(k, v as int)),
      packages:      (m['packages'] as List<dynamic>)
                       .map((e) => e as String)
                       .toList(),
    );
  }

  // ── Display helpers ───────────────────────────────────────────────────────

  String get modelLabel => switch (model) {
        'sharedHourly'  => 'Shared Hourly',
        'perAppHourly'  => 'Per-App Hourly',
        'blockLimiter'  => 'Block Limiter',
        _               => model,
      };

  String get timeRange {
    String fmt(int h, int min) {
      final period = h >= 12 ? 'PM' : 'AM';
      final hour   = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      final minute = min.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    }
    return '${fmt(startHour, startMinute)} – ${fmt(endHour, endMinute)}';
  }

  String get budgetSummary => switch (model) {
        'sharedHourly' => '$sharedBudget min/hr shared',
        'perAppHourly' => perAppBudgets.entries
            .map((e) => '${e.key.split('.').last}: ${e.value}m')
            .join(', '),
        'blockLimiter' => '$sharedBudget min block',
        _              => '',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class LimiterListPage extends StatefulWidget {
  /// If provided (navigated from NewLimiterPage right after a save), the config
  /// is decoded immediately without a SharedPreferences read. This avoids the
  /// async gap that would cause a "loading" flash on a fresh save.
  final String? initialConfigJson;

  const LimiterListPage({super.key, this.initialConfigJson});

  @override
  State<LimiterListPage> createState() => _LimiterListPageState();
}

class _LimiterListPageState extends State<LimiterListPage> {
  static const _channel = MethodChannel('uniqueChannelName');

  // We store a single active profile (MVP: one config at a time).
  // Future sprint: expand to List<LimiterProfile> with multiple saved slots.
  LimiterProfile? _profile;
  bool _loading = true;
  String? _error;

  // ── Usage data from Kotlin (getCurrentUsage) ──────────────────────────────
  int _usedMinutes = 0;
  bool _usageLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfigJson != null) {
      // Fast path: we just came from the save flow, no I/O needed
      _decodeProfile(widget.initialConfigJson!);
      _loading = false;
    } else {
      // Cold start: read from Dart-side SharedPreferences
      _loadFromPrefs();
    }
  }

  void _decodeProfile(String json) {
    try {
      _profile = LimiterProfile.fromJson(json);
    } catch (e) {
      _error = 'Failed to parse config: $e';
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json  = prefs.getString('limiterConfig');
      if (json == null) {
        setState(() => _loading = false); // No config saved yet — empty state
        return;
      }
      _decodeProfile(json);
    } catch (e) {
      _error = 'Failed to load config: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Polls Kotlin for how many minutes of the shared budget have been consumed
  /// so far during the active window today.
  Future<void> _refreshUsage() async {
    if (_profile == null) return;
    setState(() => _usageLoading = true);
    try {
      final minutes =
          await _channel.invokeMethod<int>('getCurrentUsage') ?? 0;
      setState(() => _usedMinutes = minutes);
    } catch (_) {
      // No-op; usage data is informational
    } finally {
      if (mounted) setState(() => _usageLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Color _modelColor(String model) => switch (model) {
        'sharedHourly'  => const Color(0xFF3D5AFE),
        'perAppHourly'  => const Color(0xFF6C63FF),
        'blockLimiter'  => const Color(0xFFFF6B35),
        _               => Colors.grey,
      };

  IconData _modelIcon(String model) => switch (model) {
        'sharedHourly'  => Icons.pie_chart_outline_rounded,
        'perAppHourly'  => Icons.apps_rounded,
        'blockLimiter'  => Icons.timer_outlined,
        _               => Icons.help_outline,
      };

  // ─────────────────────────────────────────────────────────────────────────
  // Profile card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _profileCard(LimiterProfile profile) {
    final color = _modelColor(profile.model);
    final budget = profile.model == 'sharedHourly'
        ? profile.sharedBudget
        : (profile.model == 'blockLimiter' ? profile.sharedBudget : 0);
    final hasProgress =
        profile.model != 'perAppHourly' && budget > 0 && profile.active;

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
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_modelIcon(profile.model),
                      color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.modelLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(profile.budgetSummary,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Switch(
                  value: profile.active,
                  activeColor: color,
                  onChanged: (_) {
                    setState(() => profile.active = !profile.active);
                    if (profile.active) _refreshUsage();
                  },
                ),
              ],
            ),
          ),

          // ── Usage progress bar (sharedHourly / blockLimiter only) ────────
          if (hasProgress) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _usageLoading
                            ? 'Checking usage…'
                            : '$_usedMinutes / $budget min used today',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 12),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh,
                            color: Colors.white.withOpacity(0.4),
                            size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _refreshUsage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_usedMinutes / budget).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor:
                          Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _usedMinutes >= budget
                            ? const Color(0xFFFF4D4D)
                            : color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],

          // ── Footer detail row ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time,
                        color: Colors.white.withOpacity(0.35),
                        size: 14),
                    const SizedBox(width: 6),
                    Text(profile.timeRange,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_android,
                        color: Colors.white.withOpacity(0.35),
                        size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        profile.packages
                            .map((p) => p.split('.').last)
                            .join(', '),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D35),
        leading: const BackButton(color: Colors.white),
        title: const Text('Saved Limiters',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF3D5AFE)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status banner ─────────────────────────────────────
                    _statusBanner(),
                    const SizedBox(height: 20),

                    // ── Content ───────────────────────────────────────────
                    Expanded(child: _body()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _statusBanner() {
    final active = _profile?.active ?? false;
    final color  = active
        ? const Color(0xFF00B686)
        : const Color(0xFF1A1D35);
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.12) : color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? color.withOpacity(0.5) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.shield_rounded : Icons.shield_outlined,
            color: active ? const Color(0xFF00B686) : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            _profile == null
                ? 'No limiter saved yet — create one first'
                : (active
                    ? 'Limiter is active — blocking enabled'
                    : 'Toggle the limiter below to start enforcement'),
            style: TextStyle(
              color: active
                  ? const Color(0xFF00B686)
                  : Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: const TextStyle(color: Color(0xFFFF4D4D))));
    }

    if (_profile == null) {
      // Nothing saved yet — guide user back
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                color: Colors.white.withOpacity(0.2), size: 56),
            const SizedBox(height: 12),
            Text(
              'No limiters saved yet.\nTap "New Limiter" on the home screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        _profileCard(_profile!),
        // Future sprint: render additional saved profiles here
      ],
    );
  }
}