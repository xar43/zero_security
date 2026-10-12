import 'package:flutter/material.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/route_manager.dart';
import 'package:toggle_timer/config/local/local_storage_services.dart';
import 'package:toggle_timer/config/notifications/app_notifications.dart';
import 'package:toggle_timer/config/theme/app_theme.dart';
import 'package:toggle_timer/features/auth/screens/splash_screen.dart';
import 'package:toggle_timer/features/sales/screens/task_overlay_screen.dart';

import 'features/home/controller/drawer_controller.dart';
import 'features/notes/controller/note_controller.dart';
import 'features/sales/controller/lead_controller.dart';
import 'features/sales/controller/location_controller.dart';
import 'features/sales/helper/notification_services.dart';

/// Entry point for the system overlay (floating window).
/// This runs in a separate isolate.
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskOverlayApp());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(NotesController());
  Get.put(AppDrawerController());
  await LocalStorageServices.instance;
  await AwesomeNotificationService().init();

  // Initialize services
  await NotificationService().init();

  // Initialize controllers
  Get.put(LocationController());
  runApp(_ToggleTimer());
}


class _ToggleTimer extends StatelessWidget {
  const _ToggleTimer();

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey,
    theme: AppTheme.darkTheme,
    home: SplashScreen(),
  );
}

final navigatorKey = GlobalKey<NavigatorState>();

final leadController = Get.put(LeadController());

