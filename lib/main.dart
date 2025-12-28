import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive_storage.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/loan_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage (non-blocking for UI)
  await HiveStorage.init();

  // Initialize notification service (non-blocking for UI)
  await NotificationService.init();

  // Run app immediately - don't block on reminder rescheduling
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
