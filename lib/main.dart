import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive_storage.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/loan_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage
  await HiveStorage.init();

  // Initialize notification service
  await NotificationService.init();

  // Reschedule all loan reminders
  final repository = LoanRepository(HiveStorage());
  final loans = await repository.getAllLoans();
  await NotificationService.rescheduleAllReminders(loans);

  runApp(
    const ProviderScope(
      child: LoanLensApp(),
    ),
  );
}
