// ignore_for_file: constant_identifier_names, avoid_print

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toggle_timer/features/sales/models/lead_model.dart';

import '../../features/sales/screens/lead_details_screen.dart';

class AwesomeNotificationService {
  static final AwesomeNotificationService _instance = AwesomeNotificationService._internal();
  factory AwesomeNotificationService() => _instance;
  AwesomeNotificationService._internal();

  static const String CHANNEL_FOLLOW_UP = 'follow_up_channel';
  static const String CHANNEL_LEAD = 'lead_channel';
  static const String CHANNEL_GENERAL = 'general_channel';

  bool _initialized = false;

  // Initialize the notification service
  Future<void> init() async {
    if (_initialized) return;

    try {
      await AwesomeNotifications().initialize(
        null, // Use default app icon
        [
          NotificationChannel(
            channelKey: CHANNEL_FOLLOW_UP,
            channelName: 'Follow-up Reminders',
            channelDescription: 'Reminders for lead follow-ups',
            defaultColor: const Color(0xFF2196F3),
            ledColor: const Color(0xFF2196F3),
            importance: NotificationImportance.High,
            channelShowBadge: true,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            soundSource: 'resource://raw/notification_sound',
            defaultRingtoneType: DefaultRingtoneType.Notification,
            locked: false,
            groupKey: 'follow_ups',
            groupAlertBehavior: GroupAlertBehavior.Children,
          ),
          NotificationChannel(
            channelKey: CHANNEL_LEAD,
            channelName: 'Lead Updates',
            channelDescription: 'Updates about your leads',
            defaultColor: const Color(0xFF4CAF50),
            ledColor: const Color(0xFF4CAF50),
            importance: NotificationImportance.Default,
            channelShowBadge: true,
            playSound: true,
          ),
          NotificationChannel(
            channelKey: CHANNEL_GENERAL,
            channelName: 'General Notifications',
            channelDescription: 'General app notifications',
            defaultColor: const Color(0xFF9C27B0),
            ledColor: const Color(0xFF9C27B0),
            importance: NotificationImportance.Default,
            playSound: true,
          ),
        ],
      );

      // Request permissions
      await requestPermissions();

      // Set notification callbacks
      _setNotificationCallbacks();

      _initialized = true;
      print('✅ Awesome Notifications initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Awesome Notifications: $e');
    }
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    return await AwesomeNotifications().isNotificationAllowed();
  }

  // Set notification action callbacks
  void _setNotificationCallbacks() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  // Handle notification when app is opened from notification
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Extract payload
    final payload = receivedAction.payload ?? {};
    final String leadId = payload['leadId'] ?? '';
    final String followUpId = payload['followUpId'] ?? '';
    final String action = receivedAction.buttonKeyPressed;

    print('📱 Notification Action: $action');
    print('📊 Payload: $payload');

    // Handle different actions
    switch (action) {
      case 'OPEN':
      case 'DEFAULT':
        final leads = await LeadModel.getAll();
        final lead = leads.firstWhereOrNull((element) => element.id == leadId);
        // Navigate to lead details
        if (leadId.isNotEmpty && lead != null) {
          // Use GetX navigation
          Get.to(() => LeadDetailsScreen(lead: lead));
        }
        break;
      case 'SNOOZE':
        // Snooze for 30 minutes
        if (followUpId.isNotEmpty && leadId.isNotEmpty) {
          await _handleSnooze(leadId, followUpId);
        }
        break;
      case 'COMPLETE':
        // Mark as complete
        if (followUpId.isNotEmpty && leadId.isNotEmpty) {
          await _handleComplete(leadId, followUpId);
        }
        break;
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    print('📝 Notification created: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    print('📢 Notification displayed: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    print('❌ Notification dismissed: ${receivedAction.id}');
  }

  // Schedule a follow-up reminder
  static Future<void> scheduleFollowUpReminder({
    required String leadId,
    required String leadName,
    required String followUpId,
    required DateTime scheduledDate,
    required String followUpType,
    String? notes,
    int reminderMinutes = 5, // Remind 5 minutes before
  }) async {
    // Calculate reminder time
    final reminderTime = scheduledDate.subtract(Duration(minutes: reminderMinutes));

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) {
      print('⏰ Reminder time is in the past, not scheduling');
      return;
    }

    // Format date for display
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledDate);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _generateNotificationId(followUpId),
        channelKey: CHANNEL_FOLLOW_UP,
        title: '🔔 Follow-up Reminder: $leadName',
        body: notes?.isNotEmpty == true
            ? '$followUpType follow-up at $formattedDate\n📝 $notes'
            : '$followUpType follow-up scheduled at $formattedDate',
        notificationLayout: NotificationLayout.BigText,
        payload: {
          'leadId': leadId,
          'followUpId': followUpId,
          'scheduledDate': scheduledDate.toIso8601String(),
          'type': followUpType,
        },
        category: NotificationCategory.Reminder,
        color: const Color(0xFF2196F3),
        icon: 'resource://drawable/ic_notification',
        bigPicture: 'asset://assets/images/notification_bg.png',
        locked: false,
        fullScreenIntent: true,
        wakeUpScreen: true,
        criticalAlert: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'COMPLETE',
          label: '✓ Complete',
          icon: 'resource://drawable/ic_check',
          autoDismissible: true,
          color: const Color(0xFF4CAF50),
        ),
        NotificationActionButton(
          key: 'SNOOZE',
          label: '⏰ Snooze',
          icon: 'resource://drawable/ic_snooze',
          autoDismissible: true,
          color: const Color(0xFFFF9800),
        ),
        NotificationActionButton(
          key: 'OPEN',
          label: '👤 View Lead',
          icon: 'resource://drawable/ic_open',
          autoDismissible: true,
          color: const Color(0xFF2196F3),
        ),
      ],
      schedule: NotificationCalendar(
        year: reminderTime.year,
        month: reminderTime.month,
        day: reminderTime.day,
        hour: reminderTime.hour,
        minute: reminderTime.minute,
        second: 0,
        millisecond: 0,
        preciseAlarm: true,
        allowWhileIdle: true,
        repeats: false,
        timeZone: "Asia/Kolkata",
      ),
    );

    print('✅ Scheduled reminder for $leadName at $reminderTime');
  }

  // Schedule a recurring follow-up
  static Future<void> scheduleRecurringFollowUp({
    required String leadId,
    required String leadName,
    required String followUpId,
    required DateTime startDate,
    required String followUpType,
    required String recurrencePattern, // daily, weekly, monthly
    int? interval, // every 2 days, every 2 weeks, etc
    DateTime? endDate,
    int? maxCount,
  }) async {
    // Create recurring notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _generateRecurringId(followUpId),
        channelKey: CHANNEL_FOLLOW_UP,
        title: '🔄 Recurring: $leadName',
        body: 'Recurring $followUpType follow-up',
        notificationLayout: NotificationLayout.BigText,
        payload: {
          'leadId': leadId,
          'followUpId': followUpId,
          'pattern': recurrencePattern,
          'interval': interval?.toString() ?? '1',
        },
        category: NotificationCategory.Reminder,
        color: const Color(0xFF2196F3),
      ),
    );
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(String followUpId) async {
    final notificationId = _generateNotificationId(followUpId);
    await AwesomeNotifications().cancel(notificationId);
    print('❌ Cancelled notification: $notificationId');
  }

  // Cancel all follow-up notifications
  static Future<void> cancelAllFollowUpNotifications() async {
    await AwesomeNotifications().cancelAll();
    print('❌ Cancelled all notifications');
  }

  // Private helper methods
  static int _generateNotificationId(String followUpId) {
    return followUpId.hashCode.abs();
  }

  static int _generateRecurringId(String followUpId) {
    return '${followUpId}_recurring'.hashCode.abs();
  }

  static Future<void> _handleSnooze(String leadId, String followUpId) async {
    // Snooze for 30 minutes
    final snoozeTime = DateTime.now().add(const Duration(minutes: 30));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _generateNotificationId('${followUpId}_snoozed'),
        channelKey: CHANNEL_FOLLOW_UP,
        title: '⏰ Snoozed Follow-up Reminder',
        body: 'You snoozed this reminder until ${DateFormat('hh:mm a').format(snoozeTime)}',
        payload: {'leadId': leadId, 'followUpId': followUpId},
      ),
      schedule: NotificationCalendar.fromDate(date: snoozeTime),
    );
  }

  static Future<void> _handleComplete(String leadId, String followUpId) async {
    // This will be implemented to mark follow-up as complete
    print('✅ Follow-up $followUpId completed via notification');
    // You can emit an event or call a service here
  }
}
