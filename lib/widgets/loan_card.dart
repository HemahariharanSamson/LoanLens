import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/loan_model.dart';
import '../core/utils/loan_calculator.dart';

/// Card widget for displaying loan information
class LoanCard extends StatelessWidget {
  final LoanModel loan;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const LoanCard({
    super.key,
    required this.loan,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    // Use new calculation methods that account for past payments and closures
    final remainingBalance = LoanCalculator.calculateOutstandingWithHistory(
      principal: loan.principalAmount,
      annualInterestRate: loan.interestRate,
      totalTenureMonths: loan.tenureInMonths,
      monthsPaidSoFar: loan.monthsPaidSoFar,
      amountPaidSoFar: loan.amountPaidSoFar,
      effectiveStartDate: loan.effectiveStartDate,
      status: loan.status,
      closureAmount: loan.closureAmount,
    );
    
    final totalPaidMonths = loan.totalMonthsPaid;
    final progress = loan.tenureInMonths > 0
        ? (totalPaidMonths / loan.tenureInMonths) * 100
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loan.loanName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (loan.isClosed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'CLOSED',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loan.lenderName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    context,
                    'EMI',
                    formatter.format(loan.emiAmount),
                  ),
                  _buildStatItem(
                    context,
                    loan.isClosed ? 'Status' : 'Outstanding',
                    loan.isClosed ? 'Closed' : formatter.format(remainingBalance),
                  ),
                  _buildStatItem(
                    context,
                    'Progress',
                    '${progress.toStringAsFixed(1)}%',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!loan.isClosed)
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Loan completed',
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
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

