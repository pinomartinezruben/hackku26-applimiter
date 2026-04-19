import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hackku_applimiter/limiter_list_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

enum LimiterModel { sharedHourly, perAppHourly, blockLimiter }

/// One installed app — returned from Kotlin's getInstalledApps call.
/// [icon] is a WebP-compressed Uint8List; null when running with stub data.
class AppEntry {
  final String name;
  final String packageId;
  final Uint8List? icon;
  bool selected;

  AppEntry({
    required this.name,
    required this.packageId,
    this.icon,
    this.selected = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class NewLimiterPage extends StatefulWidget {
  const NewLimiterPage({super.key});

  @override
  State<NewLimiterPage> createState() => _NewLimiterPageState();
}

class _NewLimiterPageState extends State<NewLimiterPage> {
  // ── Native bridge — same channel name everywhere, never duplicated ────────
  static const _channel = MethodChannel('uniqueChannelName');

  // ── App list ──────────────────────────────────────────────────────────────
  List<AppEntry> _apps = [];
  bool _appsLoading = true;
  String _searchQuery = '';

  // ── Timeframe ─────────────────────────────────────────────────────────────
  TimeOfDay _startTime = const TimeOfDay(hour: 8,  minute: 0);
  TimeOfDay _endTime   = const TimeOfDay(hour: 9,  minute: 0);

  // ── Model selection ───────────────────────────────────────────────────────
  LimiterModel _selectedModel = LimiterModel.sharedHourly;

  int _sharedBudgetMinutes  = 5;
  int _blockDurationMinutes = 30;
  final Map<String, int> _perAppBudgets = {};

  // ── Save guard ────────────────────────────────────────────────────────────
  bool _saving = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  /// Invokes Kotlin's getInstalledApps and decodes the WebP icon bytes.
  /// Falls back to a stub list if the channel is unavailable (simulator / debug).
  Future<void> _loadInstalledApps() async {
    try {
      final raw =
          await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (raw == null) throw Exception('null result');

      final apps = raw.map((item) {
        final m = Map<String, dynamic>.from(item as Map);
        return AppEntry(
          name:      m['name']      as String,
          packageId: m['packageId'] as String,
          icon:      m['icon']      as Uint8List?,
        );
      }).toList();

      setState(() {
        _apps = apps;
        _appsLoading = false;
      });
    } catch (_) {
      // Graceful fallback so the UI renders during hot-reload / no device
      setState(() {
        _apps = [
          AppEntry(name: 'YouTube',     packageId: 'com.google.android.youtube'),
          AppEntry(name: 'TikTok',      packageId: 'com.zhiliaoapp.musically'),
          AppEntry(name: 'Instagram',   packageId: 'com.instagram.android'),
          AppEntry(name: 'Twitter / X', packageId: 'com.twitter.android'),
          AppEntry(name: 'Reddit',      packageId: 'com.reddit.frontpage'),
          AppEntry(name: 'Snapchat',    packageId: 'com.snapchat.android'),
        ];
        _appsLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // _onSave  ← THE CORE OF THE INTEGRATION
  // ─────────────────────────────────────────────────────────────────────────
  //
  //  Three things happen in strict sequence:
  //
  //  1. Build the canonical JSON blob the Kotlin engine reads.
  //     Structure is exactly what LimiterService.kt expects:
  //       {
  //         "model":           "sharedHourly" | "perAppHourly" | "blockLimiter",
  //         "startTimeHour":   8,
  //         "startTimeMinute": 0,
  //         "endTimeHour":     9,
  //         "endTimeMinute":   0,
  //         "sharedBudget":    5,          // minutes; used by sharedHourly & blockLimiter
  //         "perAppBudgets":   {"com.x": 10, ...}, // used by perAppHourly
  //         "packages":        ["com.x", ...]
  //       }
  //
  //  2. Persist in Dart-side SharedPreferences (key: "limiterConfig").
  //     This lets LimiterListPage reload the config after a cold app restart
  //     without going back through the MethodChannel.
  //
  //  3. Push the same string over the MethodChannel as "saveLimiterConfig".
  //     Kotlin saves it to *native* SharedPreferences AND immediately calls
  //     startForegroundService() to boot LimiterService. LimiterService reads
  //     directly from the native SharedPreferences file — it never touches Dart.
  //
  //  Then navigate to LimiterListPage, passing the JSON so the page can render
  //  the active profile immediately with zero additional I/O.

  Future<void> _onSave() async {
    final selected = _apps.where((a) => a.selected).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one app to limit.'),
          backgroundColor: Color(0xFFFF4D4D),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    // ── 1. Canonical JSON payload ─────────────────────────────────────────
    final int effectiveBudget;
    switch (_selectedModel) {
      case LimiterModel.sharedHourly:
        effectiveBudget = _sharedBudgetMinutes;
      case LimiterModel.blockLimiter:
        effectiveBudget = _blockDurationMinutes;
      case LimiterModel.perAppHourly:
        effectiveBudget = 0; // unused; perAppBudgets map is the authority
    }

    final Map<String, dynamic> config = {
      'model':           _modelKey(_selectedModel),
      'startTimeHour':   _startTime.hour,
      'startTimeMinute': _startTime.minute,
      'endTimeHour':     _endTime.hour,
      'endTimeMinute':   _endTime.minute,
      'sharedBudget':    effectiveBudget,
      'perAppBudgets': {
        for (final app in selected)
          app.packageId: _perAppBudgets[app.packageId] ?? 10,
      },
      'packages': selected.map((a) => a.packageId).toList(),
    };

    final String jsonString = jsonEncode(config);

    try {
      // ── 2. Dart-side persistence ──────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('limiterConfig', jsonString);

      // ── 3. Kotlin bridge: save natively + boot LimiterService ─────────
      // The map key 'config' matches what Kotlin reads via call.argument("config")
      await _channel.invokeMethod('saveLimiterConfig', {'config': jsonString});

      if (!mounted) return;

      // ── Navigate, pass JSON so the list screen doesn't need another read
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LimiterListPage(initialConfigJson: jsonString),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: const Color(0xFFFF4D4D),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _modelKey(LimiterModel m) => switch (m) {
        LimiterModel.sharedHourly  => 'sharedHourly',
        LimiterModel.perAppHourly  => 'perAppHourly',
        LimiterModel.blockLimiter  => 'blockLimiter',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // UI helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF3D5AFE),
            onPrimary: Colors.white,
            surface: Color(0xFF1A1D35),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Widget _sectionHeader(String t) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 10),
        child: Text(t,
            style: const TextStyle(
                color: Color(0xFF3D5AFE),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4)),
      );

  Widget _timeTile(String label, TimeOfDay time, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
              color: const Color(0xFF1A1D35),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.access_time, color: Color(0xFF3D5AFE), size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14)),
            const Spacer(),
            Text(_fmt(time),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _stepper({
    required String label,
    required int value,
    required ValueChanged<int> onChange,
  }) =>
      Row(children: [
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14))),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: Color(0xFF3D5AFE)),
          onPressed: () => onChange((value - 5).clamp(1, 120)),
        ),
        SizedBox(
          width: 44,
          child: Text('$value m',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon:
              const Icon(Icons.add_circle_outline, color: Color(0xFF3D5AFE)),
          onPressed: () => onChange((value + 5).clamp(1, 120)),
        ),
      ]);

  Widget _modelCard({
    required LimiterModel model,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final sel = _selectedModel == model;
    return GestureDetector(
      onTap: () => setState(() => _selectedModel = model),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF3D5AFE).withOpacity(0.15)
              : const Color(0xFF1A1D35),
          border: Border.all(
              color: sel ? const Color(0xFF3D5AFE) : Colors.transparent,
              width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon,
              color: sel
                  ? const Color(0xFF3D5AFE)
                  : Colors.white.withOpacity(0.35),
              size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 12)),
              ],
            ),
          ),
          if (sel)
            const Icon(Icons.check_circle,
                color: Color(0xFF3D5AFE), size: 20),
        ]),
      ),
    );
  }

  List<AppEntry> get _filtered => _searchQuery.isEmpty
      ? _apps
      : _apps
          .where((a) =>
              a.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  List<AppEntry> get _selectedApps => _apps.where((a) => a.selected).toList();

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
        title: const Text('New Limiter',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _appsLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF3D5AFE)))
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              children: [
                // ── SELECT APPS ────────────────────────────────────────────
                _sectionHeader('SELECT APPS'),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A1D35),
                      borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search apps…',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.35)),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withOpacity(0.35)),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A1D35),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: _filtered.map((app) {
                      return CheckboxListTile(
                        secondary: app.icon != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(app.icon!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover),
                              )
                            : Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3D5AFE)
                                      .withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.android,
                                    color: Color(0xFF3D5AFE),
                                    size: 20),
                              ),
                        title: Text(app.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15)),
                        subtitle: Text(app.packageId,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 11)),
                        value: app.selected,
                        activeColor: const Color(0xFF3D5AFE),
                        checkColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withOpacity(0.2)),
                        onChanged: (v) =>
                            setState(() => app.selected = v ?? false),
                      );
                    }).toList(),
                  ),
                ),

                // ── TIMEFRAME ──────────────────────────────────────────────
                _sectionHeader('ACTIVE TIMEFRAME'),
                _timeTile('Start time', _startTime,
                    () => _pickTime(isStart: true)),
                const SizedBox(height: 10),
                _timeTile('End time', _endTime,
                    () => _pickTime(isStart: false)),

                // ── MODEL ──────────────────────────────────────────────────
                _sectionHeader('LIMITING MODEL'),
                _modelCard(
                  model: LimiterModel.sharedHourly,
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'A · Shared Hourly Cycle',
                  subtitle:
                      'All apps draw from one shared pool per hour.',
                ),
                _modelCard(
                  model: LimiterModel.perAppHourly,
                  icon: Icons.apps_rounded,
                  title: 'B · Per-App Hourly Cycle',
                  subtitle:
                      'Each app has its own independent limit per hour.',
                ),
                _modelCard(
                  model: LimiterModel.blockLimiter,
                  icon: Icons.timer_outlined,
                  title: 'C · Block Limiter',
                  subtitle:
                      'One fixed timer for a continuous usage session.',
                ),

                // ── MODEL CONFIG ───────────────────────────────────────────
                if (_selectedModel == LimiterModel.sharedHourly) ...[
                  _sectionHeader('SHARED BUDGET'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A1D35),
                        borderRadius: BorderRadius.circular(12)),
                    child: _stepper(
                      label: 'Minutes allowed per hour (shared pool)',
                      value: _sharedBudgetMinutes,
                      onChange: (v) =>
                          setState(() => _sharedBudgetMinutes = v),
                    ),
                  ),
                ],
                if (_selectedModel == LimiterModel.perAppHourly) ...[
                  _sectionHeader('PER-APP BUDGETS'),
                  _selectedApps.isEmpty
                      ? Text(
                          'Select apps above to set individual limits.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13,
                              fontStyle: FontStyle.italic),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1A1D35),
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: _selectedApps.map((app) {
                              final b =
                                  _perAppBudgets[app.packageId] ?? 10;
                              return _stepper(
                                label: app.name,
                                value: b,
                                onChange: (v) => setState(() =>
                                    _perAppBudgets[app.packageId] = v),
                              );
                            }).toList(),
                          ),
                        ),
                ],
                if (_selectedModel == LimiterModel.blockLimiter) ...[
                  _sectionHeader('BLOCK DURATION'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A1D35),
                        borderRadius: BorderRadius.circular(12)),
                    child: _stepper(
                      label: 'Total session minutes',
                      value: _blockDurationMinutes,
                      onChange: (v) =>
                          setState(() => _blockDurationMinutes = v),
                    ),
                  ),
                ],

                const SizedBox(height: 36),
                SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5AFE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _saving ? 'Saving…' : 'Save Limiter',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _saving ? null : _onSave,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}