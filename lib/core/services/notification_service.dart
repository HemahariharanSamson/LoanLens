import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../data/models/loan_model.dart';
import '../constants/app_constants.dart';

/// Service for managing local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification service
  static Future<void> init() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permissions for Android 13+
    await _requestPermissions();
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
  }

  /// Schedule EMI reminder for a loan
  static Future<void> scheduleEMIReminder(LoanModel loan) async {
    // Don't schedule for closed loans
    if (loan.isClosed) {
      await cancelEMIReminder(loan.id);
      return;
    }
    
    if (!loan.notificationsEnabled) {
      await cancelEMIReminder(loan.id);
      return;
    }

    // Use effective start date (firstEmiDate if available)
    final effectiveStartDate = loan.effectiveStartDate;
    
    // Calculate next EMI date (monthly from effective start date)
    final nextEMIDate = _calculateNextEMIDate(effectiveStartDate);
    
    // Calculate reminder date (X days before EMI)
    final reminderDate = nextEMIDate.subtract(
      Duration(days: loan.reminderDaysBefore),
    );
    
    // Only schedule if reminder date is in the future
    if (reminderDate.isBefore(DateTime.now())) {
      return;
    }

    // Schedule notification
    await _notifications.zonedSchedule(
      AppConstants.emiReminderNotificationId + loan.id.hashCode,
      'EMI Reminder: ${loan.loanName}',
      'Your EMI of ₹${loan.emiAmount.toStringAsFixed(2)} is due on ${_formatDate(nextEMIDate)}',
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'emi_reminders',
          'EMI Reminders',
          channelDescription: 'Notifications for EMI due dates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel EMI reminder for a loan
  static Future<void> cancelEMIReminder(String loanId) async {
    await _notifications.cancel(
      AppConstants.emiReminderNotificationId + loanId.hashCode,
    );
  }

  /// Calculate next EMI date
  static DateTime _calculateNextEMIDate(DateTime startDate) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, startDate.day);
    
    if (currentMonth.isBefore(now) || currentMonth.isAtSameMomentAs(now)) {
      // Next month
      if (now.month == 12) {
        return DateTime(now.year + 1, 1, startDate.day);
      } else {
        return DateTime(now.year, now.month + 1, startDate.day);
      }
    } else {
      // This month
      return currentMonth;
    }
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Reschedule all loan reminders
  static Future<void> rescheduleAllReminders(List<LoanModel> loans) async {
    for (final loan in loans) {
      await scheduleEMIReminder(loan);
    }
  }
}

