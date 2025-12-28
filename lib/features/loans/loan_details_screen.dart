import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/loan_model.dart';
import '../../data/repositories/loan_repository.dart';
import '../../core/services/notification_service.dart';
import '../../routes/app_routes.dart';
import '../dashboard/dashboard_screen.dart';

/// Provider for individual loan by ID (with stable key)
final loanByIdProvider = FutureProvider.autoDispose.family<LoanModel?, String>(
  (ref, loanId) async {
    final repository = ref.read(loanRepositoryProvider);
    return await repository.getLoanById(loanId);
  },
);

/// Provider for loan analytics (with stable key and caching)
/// Uses loanId as key for proper caching
final loanAnalyticsProvider = FutureProvider.autoDispose.family<LoanAnalytics, String>(
  (ref, loanId) async {
    final repository = ref.read(loanRepositoryProvider);
    // First get the loan
    final loan = await repository.getLoanById(loanId);
    if (loan == null) {
      throw Exception('Loan not found');
    }
    // Keep alive to cache analytics during screen lifetime
    ref.keepAlive();
    return await repository.getLoanAnalytics(loan);
  },
);

/// Screen showing detailed information about a loan
class LoanDetailsScreen extends ConsumerWidget {
  final String loanId;

  const LoanDetailsScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use family provider with stable key - won't recreate on rebuild
    final loanAsync = ref.watch(loanByIdProvider(loanId));

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Loan Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                loanAsync.whenData((loan) {
                  if (loan != null && context.mounted) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.editLoan,
                      arguments: loan,
                    );
                  }
                });
              },
              tooltip: 'Edit Loan',
            ),
          ],
        ),
        body: loanAsync.when(
        data: (loan) {
          if (loan == null) {
            return const Center(child: Text('Loan not found'));
          }

          // Use family provider with stable key (loanId) - won't recreate on rebuild
          final analyticsAsync = ref.watch(loanAnalyticsProvider(loanId));

          return analyticsAsync.when(
            data: (analytics) => _buildContent(context, ref, loan, analytics),
            loading: () => _buildLoadingState(context, loan),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading analytics: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry by invalidating the provider
                      ref.invalidate(loanAnalyticsProvider(loanId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading loan: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry by invalidating the provider
                  ref.invalidate(loanByIdProvider(loanId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// Build loading state with loan info already available
  Widget _buildLoadingState(BuildContext context, LoanModel loan) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show loan info immediately while analytics load
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.loanName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loan.lenderName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    'EMI Amount',
                    formatter.format(loan.emiAmount),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    LoanModel loan,
    LoanAnalytics analytics,
  ) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loan Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.loanName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loan.lenderName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    'Principal Amount',
                    formatter.format(loan.principalAmount),
                  ),
                  _buildInfoRow(
                    context,
                    'Interest Rate',
                    '${loan.interestRate.toStringAsFixed(2)}% ${loan.interestType}',
                  ),
                  _buildInfoRow(
                    context,
                    'EMI Amount',
                    formatter.format(loan.emiAmount),
                  ),
                  _buildInfoRow(
                    context,
                    'Start Date',
                    dateFormatter.format(loan.startDate),
                  ),
                  _buildInfoRow(
                    context,
                    'Tenure',
                    '${loan.tenure} ${loan.tenureUnit} (${loan.tenureInMonths} months)',
                  ),
                  if (loan.firstEmiDate != null)
                    _buildInfoRow(
                      context,
                      'First EMI Date',
                      dateFormatter.format(loan.firstEmiDate!),
                    ),
                  if (loan.isClosed) ...[
                    const Divider(height: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Loan Closed',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                ),
                                if (loan.closureDate != null)
                                  Text(
                                    'Closed on: ${dateFormatter.format(loan.closureDate!)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.green[700],
                                        ),
                                  ),
                                if (loan.closureAmount != null)
                                  Text(
                                    'Settlement: ${formatter.format(loan.closureAmount!)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.green[700],
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Past Payments Card (if applicable)
          if (loan.monthsPaidSoFar > 0 || loan.amountPaidSoFar > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Past Payments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Months Already Paid',
                      '${loan.monthsPaidSoFar} months',
                    ),
                    _buildInfoRow(
                      context,
                      'Amount Paid Before',
                      formatter.format(loan.amountPaidSoFar),
                    ),
                  ],
                ),
              ),
            ),
          if (loan.monthsPaidSoFar > 0 || loan.amountPaidSoFar > 0)
            const SizedBox(height: 16),
          
          const SizedBox(height: 16),

          // Progress Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: analytics.progressPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${analytics.paidMonths} of ${analytics.totalMonths} months completed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Analytics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Payable',
                  formatter.format(analytics.totalPayable),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Interest',
                  formatter.format(analytics.totalInterest),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Amount Paid',
                  formatter.format(analytics.amountPaid),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Remaining',
                  formatter.format(analytics.remainingBalance),
                  Icons.pending,
                  Colors.red,
                ),
              ),
            ],
          ),
          
          // Early Closure Button (only for ongoing loans)
          if (!loan.isClosed) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showClosureDialog(context, ref, loan),
                icon: const Icon(Icons.close),
                label: const Text('Close Loan Early'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange[100],
                  foregroundColor: Colors.orange[900],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showClosureDialog(
    BuildContext context,
    WidgetRef ref,
    LoanModel loan,
  ) async {
    final closureAmountController = TextEditingController();
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Loan Early'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to close "${loan.loanName}"?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: closureAmountController,
                decoration: InputDecoration(
                  labelText: 'Settlement Amount (₹)',
                  hintText: formatter.format(loan.principalAmount),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter settlement amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'This will mark the loan as closed and cancel all future notifications.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(closureAmountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              final repository = ref.read(loanRepositoryProvider);
              final updatedLoan = loan.copyWith(
                status: 'closed',
                closureDate: DateTime.now(),
                closureAmount: amount,
                notificationsEnabled: false,
              );

              await repository.updateLoan(updatedLoan);
              
              // Cancel notifications
              await NotificationService.cancelEMIReminder(loan.id);
              
              ref.invalidate(loansProvider);
              ref.invalidate(dashboardSummaryProvider);

              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan closed successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Loan'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}

