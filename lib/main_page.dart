import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hackku_applimiter/new_limiter_page.dart';
import 'package:hackku_applimiter/limiter_list_page.dart';
import 'package:hackku_applimiter/more_options_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // ── Native bridge ────────────────────────────────────────────────────────────
  // Kept intact so Toast / future Kotlin calls are never lost.
  final _channel = const MethodChannel('uniqueChannelName');

  Future<void> callNativeCode() async {
    try {
      await _channel.invokeMethod('userName');
    } catch (_) {}
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _buildMenuButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final btnColor = color ?? const Color(0xFF3D5AFE);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
          ),
          icon: Icon(icon, size: 22),
          label: Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D35),
        title: const Text(
          'AppLimiter',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header copy ──
              const Text(
                'What would you\nlike to do?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your screen time with precision.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // ── Primary actions ──
              _buildMenuButton(
                label: 'New Limiter',
                icon: Icons.add_circle_outline_rounded,
                color: const Color(0xFF3D5AFE),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewLimiterPage()),
                ),
              ),
              _buildMenuButton(
                label: 'Start Limiter',
                icon: Icons.play_circle_outline_rounded,
                color: const Color(0xFF00B686),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LimiterListPage()),
                ),
              ),
              _buildMenuButton(
                label: 'More Options',
                icon: Icons.tune_rounded,
                color: const Color(0xFF6C63FF),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoreOptionsPage()),
                ),
              ),

              const Spacer(),

              // ── Dev / debug button ──────────────────────────────────────────
              // Preserved so your Toast / MethodChannel is always reachable.
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.35),
                  ),
                  icon: const Icon(Icons.developer_mode, size: 16),
                  label: const Text(
                    'Test Native Connection',
                    style: TextStyle(fontSize: 13),
                  ),
                  onPressed: callNativeCode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}