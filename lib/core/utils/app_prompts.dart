import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Abstract class for centralized app prompts management
abstract class AppPrompts {
  static Future<T?> showAppDialog<T>(BuildContext context, {required Widget child}) => showGeneralDialog(
    context: context,
    barrierDismissible: false,
    pageBuilder: (context, _, _) => const SizedBox(),
    transitionBuilder: (context, animation, _, _) => ScaleTransition(
      scale: Tween<double>(begin: .5, end: 1).animate(animation),
      child: FadeTransition(opacity: Tween<double>(begin: .5, end: 1).animate(animation), child: child),
    ),
  );

  static Future<T?> showConfirmation<T>({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) => showAppDialog(
    context,
    child: Platform.isIOS
        ? CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: Text(title.split(" ")[0], style: TextStyle(color: Colors.red)),
              ),
            ],
          )
        : AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: Text(title.split(" ")[0], style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
  );

  // Snackbar types
  static const success = 'success';
  static const error = 'error';
  static const warning = 'warning';
  static const info = 'info';

  /// Show a snackbar with GetX
  static void showSnackbar({
    required String title,
    required String message,
    String type = info,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
    bool dismissible = true,
    Color? backgroundColor,
    Color? textColor,
    Widget? icon,
    VoidCallback? onTap,
    String? buttonText,
    VoidCallback? onButtonTap,
  }) {
    // Determine colors based on type
    final Color bgColor = backgroundColor ?? _getBackgroundColor(type);
    final Color txtColor = textColor ?? _getTextColor(type);
    final Widget snackbarIcon = icon ?? _getIcon(type);

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      duration: duration,
      backgroundColor: bgColor.withValues(alpha: 0.9),
      colorText: txtColor,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: snackbarIcon,
      shouldIconPulse: true,
      dismissDirection: DismissDirection.horizontal,
      isDismissible: dismissible,
      mainButton: _buildButton(buttonText, onButtonTap, txtColor),
      onTap: (_) {
        if (onTap != null) onTap();
        Get.closeCurrentSnackbar();
      },
      snackStyle: SnackStyle.FLOATING,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Show success snackbar
  static void showSuccess({
    required String message,
    String title = 'Success',
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackbar(
      title: title,
      message: message,
      type: success,
      duration: duration,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Show error snackbar
  static void showError({
    required String message,
    String title = 'Error',
    Duration duration = const Duration(seconds: 4),
  }) {
    showSnackbar(
      title: title,
      message: message,
      type: error,
      duration: duration,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  /// Show warning snackbar
  static void showWarning({
    required String message,
    String title = 'Warning',
    Duration duration = const Duration(seconds: 4),
  }) {
    showSnackbar(
      title: title,
      message: message,
      type: warning,
      duration: duration,
      icon: const Icon(Icons.warning, color: Colors.white),
    );
  }

  /// Show info snackbar
  static void showInfo({
    required String message,
    String title = 'Info',
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackbar(
      title: title,
      message: message,
      type: info,
      duration: duration,
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }

  // Private helper methods
  static Color _getBackgroundColor(String type) {
    switch (type) {
      case success:
        return Colors.green;
      case error:
        return Colors.red;
      case warning:
        return Colors.orange;
      case info:
      default:
        return Colors.blue;
    }
  }

  static Color _getTextColor(String type) {
    return Colors.white;
  }

  static Widget _getIcon(String type) {
    IconData iconData;
    switch (type) {
      case success:
        iconData = Icons.check_circle;
        break;
      case error:
        iconData = Icons.error;
        break;
      case warning:
        iconData = Icons.warning;
        break;
      case info:
      default:
        iconData = Icons.info;
    }
    return Icon(iconData, color: Colors.white);
  }

  static TextButton? _buildButton(String? text, VoidCallback? onTap, Color color) {
    if (text == null || onTap == null) return null;

    return TextButton(
      onPressed: () {
        onTap();
        Get.closeCurrentSnackbar();
      },
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Close current snackbar if any
  static void closeSnackbar() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }
}
