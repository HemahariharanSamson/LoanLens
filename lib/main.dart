import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/sqlite_storage.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/loan_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services with timeout and error handling to prevent splash screen hang
  // Run both initializations in parallel for faster startup
  try {
    await Future.wait([
      // Initialize SQLite storage - CRITICAL: Must complete successfully
      SqliteStorage().init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('ERROR: SQLite initialization timed out after 5 seconds');
          throw TimeoutException('SQLite initialization timed out');
        },
      ),
      
      // Initialize notification service with timeout (can fail without blocking app)
      NotificationService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Warning: Notification service initialization timed out after 3 seconds');
          return;
        },
      ).catchError((e) {
        debugPrint('Error initializing notifications: $e');
        return; // Notifications are optional, continue if they fail
      }),
    ], eagerError: true); // Fail fast if SQLite fails
    
    debugPrint('Initialization complete. Starting app...');
  } catch (e) {
    debugPrint('CRITICAL ERROR: Failed to initialize SQLite storage: $e');
    debugPrint('App will continue but data persistence may not work correctly.');
    // Still continue - better than crashing, but log the error clearly
  }

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
    
    final repository = LoanRepository(SqliteStorage());
    final loans = await repository.getAllLoans();
    await NotificationService.rescheduleAllReminders(loans);
  } catch (e) {
    // Silently handle errors - app should still work
    debugPrint('Error rescheduling reminders: $e');
  }
}
