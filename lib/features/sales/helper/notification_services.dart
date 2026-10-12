// ignore_for_file: constant_identifier_names

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String TRACKING_CHANNEL = 'tracking_channel';
  static const String GENERAL_CHANNEL = 'general_channel';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: TRACKING_CHANNEL,
        channelName: 'Location Tracking',
        channelDescription: 'Shows active location tracking status',
        defaultColor: const Color(0xFF2196F3),
        ledColor: const Color(0xFF2196F3),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        locked: true, // Prevents swipe-to-dismiss for tracking
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupKey: 'tracking',
      ),
      NotificationChannel(
        channelKey: GENERAL_CHANNEL,
        channelName: 'General Notifications',
        channelDescription: 'App notifications and alerts',
        defaultColor: const Color(0xFF4CAF50),
        ledColor: const Color(0xFF4CAF50),
        importance: NotificationImportance.Default,
        channelShowBadge: true,
        playSound: true,
      ),
    ]);

    await requestPermissions();
    _setCallbacks();
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return await AwesomeNotifications().isNotificationAllowed();
  }

  void _setCallbacks() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
      onNotificationCreatedMethod: onNotificationCreated,
      onNotificationDisplayedMethod: onNotificationDisplayed,
      onDismissActionReceivedMethod: onDismissActionReceived,
    );
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    //final payload = receivedAction.payload ?? {};
    final String action = receivedAction.buttonKeyPressed;

    switch (action) {
      case 'STOP_TRACKING':
        // Handle stop tracking action
        // You can use EventBus or GetX to communicate with controller
        break;
      case 'VIEW_SESSION':
        //final sessionId = payload['sessionId'];
        // Navigate to session details
        break;
      case 'DISMISS':
        // Just dismiss
        break;
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreated(ReceivedNotification receivedNotification) async {
    // Notification created
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayed(ReceivedNotification receivedNotification) async {
    // Notification displayed
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceived(ReceivedAction receivedAction) async {
    // Notification dismissed
  }

  // MARK: - Tracking Notifications
  static Future<void> showTrackingNotification({
    required String title,
    required String body,
    bool ongoing = false,
    String? sessionId,
    int progress = -1,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _getTrackingNotificationId(),
        channelKey: TRACKING_CHANNEL,
        title: title,
        body: body,
        notificationLayout: ongoing ? NotificationLayout.Messaging : NotificationLayout.Default,
        payload: {'sessionId': sessionId ?? ''},
        category: NotificationCategory.Progress,
        color: const Color(0xFF2196F3),
        icon: 'resource://drawable/ic_location',
        locked: ongoing,
        wakeUpScreen: true,
        showWhen: true,
        displayOnForeground: true,
        displayOnBackground: true,
      ),
      actionButtons: ongoing
          ? [
              NotificationActionButton(
                key: 'STOP_TRACKING',
                label: '⏹️ Stop Tracking',
                actionType: ActionType.Default,
                isDangerousOption: true,
                color: Colors.red,
              ),
              NotificationActionButton(key: 'VIEW_SESSION', label: '👁️ View', actionType: ActionType.Default),
            ]
          : [NotificationActionButton(key: 'DISMISS', label: 'Dismiss', actionType: ActionType.DismissAction)],
    );
  }

  static Future<void> cancelTrackingNotification() async {
    await AwesomeNotifications().cancel(_getTrackingNotificationId());
  }

  // MARK: - General Notifications
  static Future<void> showSuccessNotification(String message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _generateId(),
        channelKey: GENERAL_CHANNEL,
        title: '✅ Success',
        body: message,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF4CAF50),
        icon: 'resource://drawable/ic_success',
      ),
    );
  }

  static Future<void> showErrorNotification(String message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _generateId(),
        channelKey: GENERAL_CHANNEL,
        title: '❌ Error',
        body: message,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFFF44336),
        icon: 'resource://drawable/ic_error',
      ),
    );
  }

  static Future<void> showInfoNotification(String title, String message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _generateId(),
        channelKey: GENERAL_CHANNEL,
        title: title,
        body: message,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF2196F3),
        icon: 'resource://drawable/ic_info',
      ),
    );
  }

  // MARK: - Private Helpers
  static int _getTrackingNotificationId() => 9999; // Fixed ID for tracking

  static int _generateId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  static Future<void> updateTrackingNotification({
    required String sessionId,
    required String duration,
    required int pointCount,
    String? location,
  }) async {
    String body = 'Duration: $duration • Points: $pointCount';
    if (location != null && location.isNotEmpty) {
      body = '📍 $location\n$body';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _getTrackingNotificationId(),
        channelKey: TRACKING_CHANNEL,
        title: '📍 Tracking Active',
        body: body,
        notificationLayout: NotificationLayout.BigText,
        payload: {'sessionId': sessionId},
        category: NotificationCategory.Progress,
        color: const Color(0xFF2196F3),
        icon: 'resource://drawable/ic_location',
        locked: true,
        wakeUpScreen: false,
        progress: pointCount % 100,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'STOP_TRACKING',
          label: '⏹️ Stop',
          actionType: ActionType.Default,
          isDangerousOption: true,
          color: Colors.red,
          icon: 'resource://drawable/ic_stop',
        ),
        NotificationActionButton(
          key: 'VIEW_SESSION',
          label: '👁️ View',
          actionType: ActionType.Default,
          color: Colors.blue,
          icon: 'resource://drawable/ic_view',
        ),
      ],
    );
  }
}
