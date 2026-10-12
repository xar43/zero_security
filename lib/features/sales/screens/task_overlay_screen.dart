import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';


class TaskOverlayApp extends StatelessWidget {
  const TaskOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TaskOverlayScreen(),
    );
  }
}

class TaskOverlayScreen extends StatefulWidget {
  const TaskOverlayScreen({super.key});

  @override
  State<TaskOverlayScreen> createState() => _TaskOverlayScreenState();
}

class _TaskOverlayScreenState extends State<TaskOverlayScreen> {
  // SharedPreferences keys (must match home_screen.dart)
  static const String _keyActiveStored = "active_seconds_stored";
  static const String _keyCallStored = "call_seconds_stored";
  static const String _keyActiveStart = "active_start_time";
  static const String _keyCallStart = "call_start_time";
  static const String _keyStatus = "selected_status";
  static const String _notesKey = "notes_data";

  int _activeSecondsStored = 0;
  int _inCallSecondsStored = 0;
  DateTime? _activeStartTime;
  DateTime? _inCallStartTime;
  String _selectedStatus = "Inactive";

  // Open notes (only titles) for PIP display
  List<String> _openNoteTitles = [];

  Timer? _uiTimer;
  bool _showControls = false;

  int get _activeSeconds {
    if (_activeStartTime == null) return _activeSecondsStored;
    return _activeSecondsStored +
        DateTime.now().difference(_activeStartTime!).inSeconds;
  }

  int get _inCallSeconds {
    if (_inCallStartTime == null) return _inCallSecondsStored;
    return _inCallSecondsStored +
        DateTime.now().difference(_inCallStartTime!).inSeconds;
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatSeconds(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${_two(h)}:${_two(m)}:${_two(s)}';
    }
    return '${_two(m)}:${_two(s)}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    // Refresh every second
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Listen to messages from the main app (e.g., status updates)
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && data.containsKey('status')) {
        setState(() {
          _selectedStatus = data['status'] as String;
        });
        _loadData();
      }
      // Refresh notes when main app sends update
      if (data is Map && data.containsKey('refresh_notes')) {
        _loadNotes();
      }
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final activeStartMillis = prefs.getInt(_keyActiveStart);
    final callStartMillis = prefs.getInt(_keyCallStart);

    if (mounted) {
      setState(() {
        _activeSecondsStored = prefs.getInt(_keyActiveStored) ?? 0;
        _inCallSecondsStored = prefs.getInt(_keyCallStored) ?? 0;
        _activeStartTime = activeStartMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(activeStartMillis)
            : null;
        _inCallStartTime = callStartMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(callStartMillis)
            : null;
        _selectedStatus = prefs.getString(_keyStatus) ?? "Inactive";
      });
    }
    await _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_notesKey);
    if (jsonString == null) {
      if (mounted) setState(() => _openNoteTitles = []);
      return;
    }
    try {
      final decoded = jsonDecode(jsonString) as List;
      final titles = decoded
          .where((e) => e['isOpen'] == true)
          .map<String>((e) => e['title'] as String)
          .toList();
      if (mounted) setState(() => _openNoteTitles = titles);
    } catch (_) {
      if (mounted) setState(() => _openNoteTitles = []);
    }
  }

  Future<void> _stopTimer() async {
    final prefs = await SharedPreferences.getInstance();

    // Accumulate stored seconds
    if (_activeStartTime != null) {
      final acc = _activeSecondsStored +
          DateTime.now().difference(_activeStartTime!).inSeconds;
      await prefs.setInt(_keyActiveStored, acc);
      await prefs.remove(_keyActiveStart);
    }
    if (_inCallStartTime != null) {
      final acc = _inCallSecondsStored +
          DateTime.now().difference(_inCallStartTime!).inSeconds;
      await prefs.setInt(_keyCallStored, acc);
      await prefs.remove(_keyCallStart);
    }
    await prefs.setString(_keyStatus, "Inactive");

    // Notify main app
    await FlutterOverlayWindow.shareData({'action': 'stop_timer'});
    await FlutterOverlayWindow.closeOverlay();
  }

  Future<void> _openApp() async {
    await FlutterOverlayWindow.shareData({'action': 'open_app'});
    await FlutterOverlayWindow.closeOverlay();
  }

  /// Notes button — app foreground mein laao aur notes screen open karo
  Future<void> _openNotes() async {
    await FlutterOverlayWindow.shareData({'action': 'open_notes'});
    await FlutterOverlayWindow.closeOverlay();
  }

  /// Cross button - dono (floating window + app) ek saath band karo
  Future<void> _closeAll() async {
    await FlutterOverlayWindow.shareData({'action': 'close_app'});
    await FlutterOverlayWindow.closeOverlay();
  }

  Color get _statusColor {
    switch (_selectedStatus) {
      case "Active":
        return const Color(0xFF4CAF50);
      case "In-Call":
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get _timerLabel {
    if (_selectedStatus == "Active") return "Active";
    if (_selectedStatus == "In-Call") return "In-Call";
    return "Idle";
  }

  String get _timerValue {
    if (_selectedStatus == "Active") return _formatSeconds(_activeSeconds);
    if (_selectedStatus == "In-Call") return _formatSeconds(_inCallSeconds);
    return "--:--";
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = _openNoteTitles.isNotEmpty;
    // Expanded height bhi notes ke hisaab se adjust karo
    final expandedHeight = _showControls
        ? (hasNotes ? 160.0 : 110.0)
        : (hasNotes ? 90.0 : 64.0);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _showControls ? 200 : 160,
          height: expandedHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D2137), Color(0xFF1A3A4A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _statusColor.withOpacity(0.35),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // --- Main content ---
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // ── Timer row ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Pulsing status dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _statusColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: _statusColor, blurRadius: 6),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _timerLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF90A4AE),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _timerValue,
                                    style: TextStyle(
                                      color: _selectedStatus == "Inactive"
                                          ? Colors.grey
                                          : Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Notes icon button (timer ke right mein) ──
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _openNotes(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD54F).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFD54F).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    const Icon(
                                      Icons.sticky_note_2_rounded,
                                      color: Color(0xFFFFD54F),
                                      size: 18,
                                    ),
                                    if (hasNotes)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF5252),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Sticky note preview strip (always visible if notes exist) ──
                      if (hasNotes) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _openNotes(),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFD54F).withOpacity(0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.notes_rounded,
                                  color: Color(0xFFFFD54F),
                                  size: 12,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    _openNoteTitles.first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFFECB3),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (_openNoteTitles.length > 1)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD54F).withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+${_openNoteTitles.length - 1}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD54F),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // ── Control buttons (shown on tap) ──
                      if (_showControls) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Open App
                            _controlButton(
                              icon: Icons.open_in_full_rounded,
                              color: const Color(0xFF42A5F5),
                              onTap: _openApp,
                            ),
                            const SizedBox(width: 10),
                            // Open Notes
                            _controlButton(
                              icon: Icons.sticky_note_2_rounded,
                              color: const Color(0xFFFFD54F),
                              onTap: _openNotes,
                            ),
                            const SizedBox(width: 10),
                            // Stop Timer
                            _controlButton(
                              icon: Icons.stop_circle_rounded,
                              color: const Color(0xFFFFB74D),
                              onTap: _stopTimer,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // --- Cross button (always visible top-right) ---
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _closeAll,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
