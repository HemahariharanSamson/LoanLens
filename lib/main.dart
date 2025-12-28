import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive_storage.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/loan_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services with timeout and error handling to prevent splash screen hang
  // Run both initializations in parallel for faster startup
  await Future.wait([
    // Initialize Hive storage with timeout
    HiveStorage.init().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('Warning: Hive initialization timed out after 3 seconds');
        return;
      },
    ).catchError((e) {
      debugPrint('Error initializing Hive: $e');
      return;
    }),
    
    // Initialize notification service with timeout
    NotificationService.init().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('Warning: Notification service initialization timed out after 3 seconds');
        return;
      },
    ).catchError((e) {
      debugPrint('Error initializing notifications: $e');
      return;
    }),
  ], eagerError: false); // Don't fail if one fails

  debugPrint('Initialization complete. Starting app...');

  // Run app immediately - don't wait for reminder rescheduling
  runApp(
    const ProviderScope(
      child: LoanLensApp(),
    ),
  );

  // Reschedule reminders in background after app starts
  // This prevents blocking the splash screen
  _rescheduleRemindersInBackground();
}

/// Reschedule loan reminders in background without blocking UI
Future<void> _rescheduleRemindersInBackground() async {
  try {
    // Small delay to ensure app is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));
    
    final repository = LoanRepository(HiveStorage());
    final loans = await repository.getAllLoans();
    await NotificationService.rescheduleAllReminders(loans);
  } catch (e) {
    // Silently handle errors - app should still work
    debugPrint('Error rescheduling reminders: $e');
  }
}
