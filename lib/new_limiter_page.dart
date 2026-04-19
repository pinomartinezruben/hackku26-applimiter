import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for MethodChannel

// ─────────────────────────────────────────────────────────────────────────────
// Data Models  (lightweight, no external packages)
// ─────────────────────────────────────────────────────────────────────────────

enum LimiterModel { sharedHourly, perAppHourly, blockLimiter }

class _AppEntry {
  final String name;
  final String packageId;
  bool selected;

  _AppEntry({
    required this.name,
    required this.packageId,
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
  // ── Native Bridge & Dynamic App List ───────────────────────────────────────
  final MethodChannel _channel = const MethodChannel('uniqueChannelName');
  
  List<_AppEntry> _allApps = [];
  List<_AppEntry> _filteredApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInstalledApps();
  }

  Future<void> _fetchInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getInstalledApps');
      
      final apps = result.map((item) {
        // Cast the returned map securely
        final map = item as Map<Object?, Object?>;
        return _AppEntry(
          name: map['name'] as String? ?? 'Unknown App',
          packageId: map['packageId'] as String? ?? 'unknown.package',
        );
      }).toList();

      setState(() {
        _allApps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback in case of platform error
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredApps = _allApps.where((app) {
        return app.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // ── Timeframe ──────────────────────────────────────────────────────────────
  TimeOfDay _startTime = const TimeOfDay(hour: 15, minute: 0); // 3:00 PM
  TimeOfDay _endTime   = const TimeOfDay(hour: 19, minute: 0); // 7:00 PM

  // ── Limiting model ─────────────────────────────────────────────────────────
  LimiterModel _selectedModel = LimiterModel.sharedHourly;

  // Shared hourly – single global budget (minutes)
  int _sharedBudgetMinutes = 15;

  // Per-app hourly – each selected app gets its own budget (minutes)
  final Map<String, int> _perAppBudgets = {};

  // Block limiter – one fixed duration (minutes)
  int _blockDurationMinutes = 30;

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatTime(TimeOfDay t) {
    final hour   = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  // Updated to read from _allApps instead of hardcoded _apps
  List<_AppEntry> get _selectedApps =>
      _allApps.where((a) => a.selected).toList();

  void _onSave() {
    // TODO: Serialize and persist the limiter profile (Kotlin bridge / shared_prefs)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Limiter saved! (${_selectedApps.length} app(s) selected)',
        ),
        backgroundColor: const Color(0xFF00B686),
      ),
    );
    Navigator.pop(context);
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF3D5AFE),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
      );

  // ── Time picker tile ───────────────────────────────────────────────────────
  Widget _timeTile(String label, TimeOfDay time, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF3D5AFE), size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(time),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Budget stepper ─────────────────────────────────────────────────────────
  Widget _minuteStepper({
    required String label,
    required int value,
    required ValueChanged<int> onChange,
  }) =>
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF3D5AFE)),
            onPressed: () => onChange((value - 5).clamp(5, 120)),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value m',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF3D5AFE)),
            onPressed: () => onChange((value + 5).clamp(5, 120)),
          ),
        ],
      );

  // ── Model card ─────────────────────────────────────────────────────────────
  Widget _modelCard({
    required LimiterModel model,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _selectedModel == model;
    return GestureDetector(
      onTap: () => setState(() => _selectedModel = model),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3D5AFE).withOpacity(0.18)
              : const Color(0xFF1A1D35),
          border: Border.all(
            color: selected ? const Color(0xFF3D5AFE) : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFF3D5AFE)
                    : Colors.white.withOpacity(0.4),
                size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF3D5AFE), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D35),
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'New Limiter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        children: [
          // ── 1. App Selection ────────────────────────────────────────────────
          _sectionHeader('SELECT APPS'),
          
          // Search Bar
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3D5AFE)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Dynamic App List
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF3D5AFE)),
                    ),
                  )
                : _filteredApps.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No apps found.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4)),
                          ),
                        ),
                      )
                    : Column(
                        children: _filteredApps.map((app) {
                          return CheckboxListTile(
                            title: Text(
                              app.name,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            subtitle: Text(
                              app.packageId,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11,
                              ),
                            ),
                            value: app.selected,
                            activeColor: const Color(0xFF3D5AFE),
                            checkColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.25)),
                            onChanged: (v) =>
                                setState(() => app.selected = v ?? false),
                          );
                        }).toList(),
                      ),
          ),

          // ── 2. Active Timeframe ─────────────────────────────────────────────
          _sectionHeader('ACTIVE TIMEFRAME'),
          _timeTile(
            'Start time',
            _startTime,
            () => _pickTime(isStart: true),
          ),
          const SizedBox(height: 10),
          _timeTile(
            'End time',
            _endTime,
            () => _pickTime(isStart: false),
          ),

          // ── 3. Limiting Model ───────────────────────────────────────────────
          _sectionHeader('LIMITING MODEL'),
          _modelCard(
            model: LimiterModel.sharedHourly,
            icon: Icons.pie_chart_outline_rounded,
            title: 'A · Shared Hourly Cycle',
            subtitle: 'All selected apps draw from one shared time budget.',
          ),
          _modelCard(
            model: LimiterModel.perAppHourly,
            icon: Icons.apps_rounded,
            title: 'B · Per-App Hourly Cycle',
            subtitle: 'Each app has its own independent time budget.',
          ),
          _modelCard(
            model: LimiterModel.blockLimiter,
            icon: Icons.timer_outlined,
            title: 'C · Block Limiter',
            subtitle: 'A single fixed timer for a continuous usage block.',
          ),

          // ── 4. Model-specific config ────────────────────────────────────────
          if (_selectedModel == LimiterModel.sharedHourly) ...[
            _sectionHeader('SHARED BUDGET'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _minuteStepper(
                label: 'Minutes allowed per hour (total)',
                value: _sharedBudgetMinutes,
                onChange: (v) => setState(() => _sharedBudgetMinutes = v),
              ),
            ),
          ],

          if (_selectedModel == LimiterModel.perAppHourly) ...[
            _sectionHeader('PER-APP BUDGETS'),
            if (_selectedApps.isEmpty)
              Text(
                'Select at least one app above to configure per-app limits.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _selectedApps.map((app) {
                    final budget = _perAppBudgets[app.packageId] ?? 10;
                    return _minuteStepper(
                      label: app.name,
                      value: budget,
                      onChange: (v) => setState(
                          () => _perAppBudgets[app.packageId] = v),
                    );
                  }).toList(),
                ),
              ),
          ],

          if (_selectedModel == LimiterModel.blockLimiter) ...[
            _sectionHeader('BLOCK DURATION'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _minuteStepper(
                label: 'Total minutes for the block',
                value: _blockDurationMinutes,
                onChange: (v) => setState(() => _blockDurationMinutes = v),
              ),
            ),
          ],

          // ── Save ────────────────────────────────────────────────────────────
          const SizedBox(height: 36),
          SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Save Limiter',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              onPressed: _onSave,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}