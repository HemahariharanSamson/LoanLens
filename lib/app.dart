import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/loans/add_edit_loan_screen.dart';
import 'features/loans/loan_details_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'data/models/loan_model.dart';

/// Main application widget
class LoanLensApp extends StatelessWidget {
  const LoanLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoanLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      // Performance optimizations
      builder: (context, child) {
        // Return child directly - MaterialApp handles performance optimizations
        return child!;
      },
      initialRoute: AppRoutes.dashboard,
      routes: {
        AppRoutes.dashboard: (context) => const DashboardScreen(),
        AppRoutes.addLoan: (context) => const AddEditLoanScreen(),
        AppRoutes.editLoan: (context) {
          final loan = ModalRoute.of(context)!.settings.arguments as LoanModel?;
          return AddEditLoanScreen(loan: loan);
        },
        AppRoutes.loanDetails: (context) {
          final loanId = ModalRoute.of(context)!.settings.arguments as String;
          return LoanDetailsScreen(loanId: loanId);
        },
        AppRoutes.analytics: (context) => const AnalyticsScreen(),
      },
    );
  }
}

