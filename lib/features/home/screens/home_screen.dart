// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toggle_timer/core/utils/app_utils.dart';
import 'package:toggle_timer/features/home/widgets/app_drawer.dart';

import '../../../config/colors/app_colors.dart';
import '../../../config/typography/app_typography.dart';
import '../../../core/common_widgets/custom_text_field.dart';
import '../../../core/helper/app_helper.dart';
import '../../../config/api/api_services.dart';
import '../../../config/constants/url_constants.dart';
import '../../../config/local/local_storage_services.dart';
import '../../notes/controller/note_controller.dart';
import '../../notes/screens/note_history_screen.dart';
import '../controller/drawer_controller.dart';
import '../widgets/UI_helpers.dart';
import 'announcement_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController noteCtrl = TextEditingController();
  static const MethodChannel _appChannel = MethodChannel('com.example.toggle_timer/app');

  bool _noteError = false;
  bool _statusError = false;
  bool _isPipMode = false;

  bool? _selectedNoteStatus = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const double _topCardHeight = 100;

  final List<String> _statuses = [
    "Active",
    "Inactive",
    "In-Call",
    "Job Logout",
  ];

  String _selectedStatus = "Inactive";

  Timer? _uiTimer;
  int _activeSecondsStored = 0;
  int _inCallSecondsStored = 0;
  DateTime? _activeStartTime;
  DateTime? _inCallStartTime;
  DateTime _currentDay = DateTime.now();

  static const String _keyActiveStored = "active_seconds_stored";
  static const String _keyCallStored = "call_seconds_stored";
  static const String _keyActiveStart = "active_start_time";
  static const String _keyCallStart = "call_start_time";
  static const String _keyStatus = "selected_status";
  static const String _keyDay = "current_day";

  NotesController get notesController => Get.find<NotesController>();

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

  String get aH => _two(_activeSeconds ~/ 3600);
  String get aM => _two((_activeSeconds % 3600) ~/ 60);
  String get aS => _two(_activeSeconds % 60);

  String get cH => _two(_inCallSeconds ~/ 3600);
  String get cM => _two((_inCallSeconds % 3600) ~/ 60);
  String get cS => _two(_inCallSeconds % 60);

  StreamSubscription? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTimerData();
    notesController.loadNotes();
    _initOverlay();
  }

  Future<void> _initOverlay() async {
    // Request permission if not granted
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) {
      await FlutterOverlayWindow.requestPermission();
    }

    // Listen for messages from the overlay
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        final action = data['action'] as String?;
        if (action == 'stop_timer') {
          _pauseActiveTimer();
          _pauseInCallTimer();
          setState(() => _selectedStatus = 'Inactive');
          _saveTimerData();
        } else if (action == 'close_app') {
          // Cross button - timer band karo aur app bhi band karo
          _pauseActiveTimer();
          _pauseInCallTimer();
          _saveTimerData();
          SystemNavigator.pop(animated: true);
        } else if (action == 'open_notes') {
          // PIP notes icon tapped — navigate to Notes screen
          const MethodChannel('com.example.toggle_timer/app').invokeMethod('bringToForeground');
          Get.to(() => const NotesListScreen());
        } else if (action == 'open_app') {
          // App already in foreground when overlay closes (or it needs to come to foreground)
          const MethodChannel('com.example.toggle_timer/app').invokeMethod('bringToForeground');
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // App background mein gaya - overlay show karo
      _showOverlayIfActive();
    } else if (state == AppLifecycleState.resumed) {
      // App wapas foreground mein - overlay band karo
      _closeOverlay();
      // Reload data in case overlay changed it
      _loadTimerData();
    }
  }

  Future<void> _showOverlayIfActive() async {
    // In PiP approach, we no longer need the flutter_overlay_window plugin!
    // PiP handles the UI natively.
  }

  Future<void> _closeOverlay() async {
    final isActive = await FlutterOverlayWindow.isActive();
    if (isActive) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  Future<void> _loadTimerData() async {
    final prefs = await SharedPreferences.getInstance();

    _activeSecondsStored = prefs.getInt(_keyActiveStored) ?? 0;
    _inCallSecondsStored = prefs.getInt(_keyCallStored) ?? 0;

    final activeStartMillis = prefs.getInt(_keyActiveStart);
    final callStartMillis = prefs.getInt(_keyCallStart);

    if (activeStartMillis != null) {
      _activeStartTime = DateTime.fromMillisecondsSinceEpoch(activeStartMillis);
    }

    if (callStartMillis != null) {
      _inCallStartTime = DateTime.fromMillisecondsSinceEpoch(callStartMillis);
    }

    _selectedStatus = prefs.getString(_keyStatus) ?? "Inactive";

    final savedDayMillis = prefs.getInt(_keyDay);
    if (savedDayMillis != null) {
      _currentDay = DateTime.fromMillisecondsSinceEpoch(savedDayMillis);
    }

    _checkMidnightReset();
    _startUiTimer();

    setState(() {});
  }

  Future<void> _saveTimerData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyActiveStored, _activeSecondsStored);
    await prefs.setInt(_keyCallStored, _inCallSecondsStored);

    if (_activeStartTime != null) {
      await prefs.setInt(
          _keyActiveStart, _activeStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyActiveStart);
    }

    if (_inCallStartTime != null) {
      await prefs.setInt(
          _keyCallStart, _inCallStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyCallStart);
    }

    await prefs.setString(_keyStatus, _selectedStatus);
    await prefs.setInt(_keyDay, _currentDay.millisecondsSinceEpoch);
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _appChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPipChanged') {
        if (mounted) {
          setState(() {
            _isPipMode = call.arguments as bool;
          });
        }
      } else if (call.method == 'openNotesFromPiP') {
        Get.to(() => const NotesListScreen());
      }
    });

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkMidnightReset();
      setState(() {});
    });
  }

  void _checkMidnightReset() {
    final now = DateTime.now();

    final isNewDay = now.day != _currentDay.day ||
        now.month != _currentDay.month ||
        now.year != _currentDay.year;

    if (isNewDay) {
      _activeSecondsStored = 0;
      _inCallSecondsStored = 0;

      _activeStartTime = null;
      _inCallStartTime = null;

      _selectedStatus = "Inactive";
      _currentDay = now;

      _saveTimerData();
    }
  }

  void _startActiveTimer() {
    if (_activeStartTime != null) return;
    _activeStartTime = DateTime.now();
    _saveTimerData();
  }

  void _pauseActiveTimer() {
    if (_activeStartTime == null) return;

    _activeSecondsStored +=
        DateTime.now().difference(_activeStartTime!).inSeconds;

    _activeStartTime = null;
    _saveTimerData();
  }

  void _startInCallTimer() {
    if (_inCallStartTime != null) return;
    _inCallStartTime = DateTime.now();
    _saveTimerData();
  }

  void _pauseInCallTimer() {
    if (_inCallStartTime == null) return;

    _inCallSecondsStored +=
        DateTime.now().difference(_inCallStartTime!).inSeconds;

    _inCallStartTime = null;
    _saveTimerData();
  }

  Future<void> _onStatusChanged(String status) async {
    setState(() => _selectedStatus = status);

    final apiServices = ApiServices();
    final empId = LocalStorageServices.getEmployeeId();
    final company = LocalStorageServices.getCompany();

    // Debug: Check what values are stored
    debugPrint('🔍 empId: $empId | company: $company | status: $status');

    if (status == "Inactive") {
      _pauseActiveTimer();
      _pauseInCallTimer();
    } else if (status == "Active") {
      _pauseInCallTimer();
      _startActiveTimer();
      if (empId != null && company != null) {
        try {
          await apiServices.postRequest(UrlConstants.punchInUrl, body: {"employee_id": empId, "company": company});
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Punched In Successfully!'), backgroundColor: Colors.green));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Punch In Failed: $e'), backgroundColor: Colors.red));
        }
      } else {
        // empId ya company nahi mila — user ne re-login nahi kiya
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Session expired. Please logout and login again.'), backgroundColor: Colors.orange));
      }
    } else if (status == "In-Call") {
      _pauseActiveTimer();
      _startInCallTimer();
      if (empId != null && company != null) {
        try {
          await apiServices.patchRequest(UrlConstants.updateStatusUrl, body: {"employee_id": empId, "company": company, "status": "In-Call"});
          debugPrint('✅ Status updated to In-Call');
        } catch (e) {
          debugPrint('⚠️ Update status failed: $e');
        }
      }
    } else if (status == "Job Logout") {
      _pauseActiveTimer();
      _pauseInCallTimer();
      if (empId != null && company != null) {
        try {
          await apiServices.postRequest(UrlConstants.punchOutUrl, body: {"employee_id": empId, "company": company});
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Punched Out Successfully!'), backgroundColor: Colors.green));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Punch Out Failed: $e'), backgroundColor: Colors.red));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Session expired. Please logout and login again.'), backgroundColor: Colors.orange));
      }
    } else if (status == "Inactive") {
      _pauseActiveTimer();
      _pauseInCallTimer();
      if (empId != null && company != null) {
        try {
          await apiServices.patchRequest(UrlConstants.updateStatusUrl, body: {"employee_id": empId, "company": company, "status": "Inactive"});
          debugPrint('✅ Status updated to Inactive');
        } catch (e) {
          debugPrint('⚠️ Update status failed: $e');
        }
      }
    }

    _saveTimerData();
  }

  Future<void> _submitHomeNote() async {
    final text = noteCtrl.text.trim();

    if (text.isEmpty) {
      setState(() => _noteError = true);
      return;
    }

    if (_selectedNoteStatus == null) {
      setState(() => _statusError = true);
      return;
    }

    setState(() {
      _noteError = false;
      _statusError = false;
    });

    // Step 1: Pehle local (SQLite) mein save karo
    await notesController.addNote(text, _selectedNoteStatus!);

    // Step 2: Backend par bhi send karo (Sticky Note API)
    final empId = LocalStorageServices.getEmployeeId();
    final company = LocalStorageServices.getCompany();
    final apiServices = ApiServices();

    if (empId != null && company != null) {
      try {
        await apiServices.postRequest(
          UrlConstants.addStickyNoteUrl,
          body: {
            "employee_id": empId,
            "company": company,
            "note": text,
            "status": _selectedNoteStatus! ? "Open" : "Closed",
          },
        );
        debugPrint('✅ Sticky note backend par bhi save ho gayi!');
      } catch (e) {
        // Backend fail hone par bhi local note save hai, toh error sirf log karein
        debugPrint('⚠️ Sticky note backend save failed: $e');
      }
    } else {
      debugPrint('⚠️ empId/company null hai — sticky note sirf local mein save hui');
    }

    noteCtrl.clear();

    setState(() {
      _selectedNoteStatus = false; // Reset Closed
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlaySubscription?.cancel();
    _uiTimer?.cancel();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPipMode) {
      // ── PiP mode UI ──
      final bool isActive =
          _selectedStatus == 'Active' || _selectedStatus == 'In-Call';
      final Color statusColor = _selectedStatus == 'Active'
          ? const Color(0xFF4CAF50)
          : _selectedStatus == 'In-Call'
              ? const Color(0xFF2196F3)
              : const Color(0xFF9E9E9E);
      final int seconds =
          _selectedStatus == 'Active' ? _activeSeconds : _inCallSeconds;

      // Get open notes from controller
      final openNotes = notesController.openNotes;

      return Scaffold(
        backgroundColor: const Color(0xFF0A1929),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D2137),
                const Color(0xFF1A3A4A),
                statusColor.withOpacity(0.08),
              ],
            ),
            border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Timer row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status dot
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: statusColor, blurRadius: 5),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Timer value
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedStatus.toUpperCase(),
                            style: TextStyle(
                              color: statusColor.withOpacity(0.85),
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            isActive ? _formatSeconds(seconds) : '--:--',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notes icon button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // Note: Android PiP typically intercepts touches, but we'll add the route just in case.
                        Get.to(() => const NotesListScreen());
                      },
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
                            if (openNotes.isNotEmpty)
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
                // ── Sticky note strip (up to 3 open notes) ──
                if (openNotes.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withOpacity(0.3),
                        width: 0.7,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < openNotes.length && i < 3; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: i < 2 && i < openNotes.length - 1 ? 3.0 : 0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.notes_rounded,
                                  color: Color(0xFFFFD54F),
                                  size: 10,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    openNotes[i].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFFECB3),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (openNotes.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              '+${openNotes.length - 3} more items',
                              style: TextStyle(
                                color: const Color(0xFFFFD54F).withOpacity(0.8),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Back press par pehle overlay show karo, phir app ko background mein bhejo
        try {
          await _showOverlayIfActive();
          await _appChannel.invokeMethod('moveToBackground');
        } catch (e) {
          debugPrint("ERROR ON BACK PRESS: $e");
        }
        return false; // App ko close hone se roko
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        flexibleSpace: AppUtils.gradientFlexibleSpace(),
        leading: AppHelper.buildDrawerButton(_scaffoldKey),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _topStats(),
                    const SizedBox(height: 16),
                    _statusCard(),
                  ],
                ),
              ),
              _activitySection(),
            ],
          ),
        ),
      ),
      ),  // Scaffold
    );   // PopScope
  }

  Widget _topStats() => Row(
    children: [
      Expanded(child: _activeTimerCard()),
      const SizedBox(width: 12),
      Expanded(child: _callTimeCard()),
    ],
  );

  Widget _activeTimerCard() => _timerCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTopRow("Active timer", "10:00AM"),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TimeWithColon(aH, "Hrs", showColon: true),
            TimeWithColon(aM, "Min", showColon: true),
            TimeWithColon(aS, "Sec", showColon: false),
          ],
        ),
      ],
    ),
  );

  Widget _callTimeCard() => _timerCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTopRow("In call time", "Total"),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TimeWithColon(cH, "Hrs", showColon: true),
            TimeWithColon(cM, "Min", showColon: true),
            TimeWithColon(cS, "Sec", showColon: false),
          ],
        ),
      ],
    ),
  );

  Widget _timerCard({required Widget child}) => SizedBox(
    height: _topCardHeight,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E4F43),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    ),
  );

  Widget _cardTopRow(String title, String trailing) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style:
          AppTypography.style12SemiBold.copyWith(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Text(
        trailing,
        style: AppTypography.style10Regular.copyWith(color: Colors.white70),
      ),
    ],
  );

  Widget _statusCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E4F43),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("Your status", _selectedStatus),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _statuses.map((status) {
            final isActive = status == _selectedStatus;
            return GestureDetector(
              onTap: () => _onStatusChanged(status),
              child: StatusChip(status, isActive),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _activitySection() => ClipRRect(
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(28),
      topRight: Radius.circular(28),
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF2A2A2A),
      child: Column(
        children: [
        // --- TEMPORARY TEST BUTTON ---
        ElevatedButton(
          onPressed: () async {
            try {
              await _appChannel.invokeMethod('moveToBackground');
            } catch (e) {
              debugPrint("PiP ERROR: $e");
            }
          },
          child: const Text("TEST: Enter PiP Mode Manually"),
        ),
        const SizedBox(height: 16),
        // -----------------------------
          _innerBox(child: _yourActivity()),
          const SizedBox(height: 16),
          _innerBox(child: _announcementBox()),
          const SizedBox(height: 16),
          _innerBox(child: _addNoteBox()),
          const SizedBox(height: 16),
          _innerBox(child: _notesPreviewBox()),
          const SizedBox(height: 16),
          _innerBox(child: _reportsBox()),
        ],
      ),
    ),
  );

  Widget _yourActivity() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Your Activity",
        style: AppTypography.style18SemiBold.copyWith(color: Colors.white),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                YAxisLabel("60h"),
                YAxisLabel("50h"),
                YAxisLabel("40h"),
                YAxisLabel("30h"),
                YAxisLabel("20h"),
                YAxisLabel("10h"),
                YAxisLabel("0h"),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  ActivityBarGroup(16, 22, "Jan-Feb"),
                  ActivityBarGroup(30, 42, "Mar-Apr"),
                  ActivityBarGroup(45, 62, "May-Jun"),
                  ActivityBarGroup(36, 52, "Jul-Aug"),
                  ActivityBarGroup(12, 18, "Sep-Oct"),
                  ActivityBarGroup(44, 60, "Nov-Dec"),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _announcementBox() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        "Announcement",
        "View All",
        icon: Icons.push_pin,
        onTapTrailing: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AnnouncementListScreen(),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      ...List.generate(3, (_) => _announcementItem()),
    ],
  );

  Widget _notesPreviewBox() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        "Notes",
        "View All",
        icon: Icons.note_alt_outlined,
        onTapTrailing: () {
          final drawerController = Get.find<AppDrawerController>();
          drawerController.setSelectedIndex("Notes");
          Navigator.pop(context);
          Get.to(() => const NotesListScreen());
        },
      ),
      const SizedBox(height: 12),
      Obx(() {
        final allNotes = [
          ...notesController.openNotes,
          ...notesController.closedNotes
        ];

        allNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        final last3 =
        allNotes.length > 3 ? allNotes.sublist(0, 3) : allNotes;

        if (last3.isEmpty) {
          return const Text(
            "No notes available",
            style: TextStyle(color: Colors.white54),
          );
        }

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: last3.length,
            itemBuilder: (_, index) {
              final note = last3[index];
              return _noteCardPreview(
                description: note.title,
                status: note.isOpen,
              );
            },
          ),
        );
      }),
    ],
  );

  Widget _noteCardPreview({
    required String description,
    required bool status,
  }) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kAppSecondary.withOpacity(.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Note",
            style: AppTypography.style12SemiBold.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            "Description : $description",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.style12Regular.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            "Status : ${status ? "Open" : "Closed"}",
            style: AppTypography.style12Regular.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _announcementItem() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      "hello, This is an Announcement",
      style: AppTypography.style12Regular.copyWith(color: Colors.white),
    ),
  );

  Widget _addNoteBox() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Add a note",
        style: AppTypography.style16SemiBold.copyWith(color: Colors.white),
      ),
      const SizedBox(height: 10),
      CustomTextField(
        controller: noteCtrl,
        maxLines: 4,
        hintText: _noteError ? "Note cannot be empty" : "Write your note here",
        hintStyle: _noteError
            ? AppTypography.style16Regular.copyWith(color: Colors.red)
            : null,
        errorText: _noteError ? "" : null,
        onChanged: (_) {
          if (_noteError) {
            setState(() => _noteError = false);
          }
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<bool>(
        value: _selectedNoteStatus,
        dropdownColor: AppColors.kAppBackground,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.kAppSecondary.withOpacity(.18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorText: _statusError ? "Please select status" : null,
        ),
        items: const [
          DropdownMenuItem(value: true, child: Text("Open")),
          DropdownMenuItem(value: false, child: Text("Closed")),
        ],
        onChanged: (value) {
          setState(() {
            _selectedNoteStatus = value;
            _statusError = false;
          });
        },
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: _submitHomeNote,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Submit",
              style: AppTypography.style12SemiBold.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _innerBox({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _sectionHeader(
      String title,
      String? trailing, {
        IconData? icon,
        VoidCallback? onTapTrailing,
      }) =>
      Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTypography.style16SemiBold
                      .copyWith(color: Colors.white),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 6),
                  Icon(icon, size: 16, color: Colors.white70),
                ],
              ],
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTapTrailing,
              child: Text(
                trailing,
                style: AppTypography.style12SemiBold.copyWith(
                  color: AppColors.kAppSecondary,
                ),
              ),
            ),
        ],
      );

  Widget _reportsBox() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Recent Working Reports",
        style: AppTypography.style16SemiBold.copyWith(color: Colors.white),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _reportCard(false)),
          Expanded(child: _reportCard(true)),
        ],
      ),
    ],
  );

  Widget _reportCard(bool highlight) => Container(
    margin: const EdgeInsets.all(6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: highlight
          ? AppColors.brownColor
          : AppColors.kAppSecondary.withOpacity(.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Working Report",
          style: AppTypography.style12SemiBold.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          "Working Hrs : 8 Hr 34 Min 23 Sec",
          style: AppTypography.style12Regular.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          "Date : Tue, 7, 2025",
          style: AppTypography.style12Regular.copyWith(color: Colors.white70),
        ),
      ],
    ),
  );

}
