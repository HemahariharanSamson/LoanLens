import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/models/loan_model.dart';
import '../../core/utils/loan_calculator.dart';
import '../dashboard/dashboard_screen.dart';

/// Analytics screen with charts
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: loansAsync.when(
        data: (loans) {
          // Filter out closed loans for analytics
          final ongoingLoans = loans.where((loan) => !loan.isClosed).toList();
          
          if (ongoingLoans.isEmpty) {
            return const Center(
              child: Text('No active loans to analyze'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOutstandingDistributionChart(context, ongoingLoans),
                const SizedBox(height: 24),
                _buildEMIComparisonChart(context, ongoingLoans),
                const SizedBox(height: 24),
                _buildRepaymentTrendChart(context, loans), // Include all loans for trend
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildOutstandingDistributionChart(
    BuildContext context,
    List<LoanModel> loans,
  ) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    // Calculate outstanding for each loan (using new method with history)
    final loanData = loans.map((loan) {
      final outstanding = LoanCalculator.calculateOutstandingWithHistory(
        principal: loan.principalAmount,
        annualInterestRate: loan.interestRate,
        totalTenureMonths: loan.tenureInMonths,
        monthsPaidSoFar: loan.monthsPaidSoFar,
        amountPaidSoFar: loan.amountPaidSoFar,
        effectiveStartDate: loan.effectiveStartDate,
        status: loan.status,
        closureAmount: loan.closureAmount,
      );
      return MapEntry(loan, outstanding);
    }).toList();

    final totalOutstanding = loanData.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );

    // Generate subtle colors
    final colors = [
      const Color(0xFF64B5F6), // Soft blue
      const Color(0xFF81C784), // Soft green
      const Color(0xFFFFB74D), // Soft orange
      const Color(0xFFE57373), // Soft red
      const Color(0xFFBA68C8), // Soft purple
      const Color(0xFF4DB6AC), // Soft teal
      const Color(0xFFF48FB1), // Soft pink
      const Color(0xFFFFD54F), // Soft amber
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outstanding Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: loanData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final loanEntry = entry.value;
                    final percentage =
                        (loanEntry.value / totalOutstanding) * 100;
                    return                     PieChartSectionData(
                      value: loanEntry.value,
                      title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
                      color: colors[index % colors.length],
                      radius: 70,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...loanData.asMap().entries.map((entry) {
              final index = entry.key;
              final loan = entry.value.key;
              final outstanding = entry.value.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loan.loanName,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        formatter.format(outstanding),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEMIComparisonChart(
    BuildContext context,
    List<LoanModel> loans,
  ) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    // Sort by EMI amount
    final sortedLoans = List<LoanModel>.from(loans)
      ..sort((a, b) => a.emiAmount.compareTo(b.emiAmount));

    final maxEMI = sortedLoans.isEmpty
        ? 0.0
        : sortedLoans.map((l) => l.emiAmount).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly EMI Comparison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxEMI * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.grey[700]!.withValues(alpha: 0.9),
                      tooltipRoundedRadius: 8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sortedLoans.length) {
                            return const Text('');
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedLoans[value.toInt()].loanName,
                              style: const TextStyle(
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                        reservedSize: 45,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final formatted = formatter.format(value);
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              formatted,
                              style: const TextStyle(fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          );
                        },
                        reservedSize: 55,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedLoans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final loan = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: loan.emiAmount,
                          color: Theme.of(context).colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepaymentTrendChart(
    BuildContext context,
    List<LoanModel> loans,
  ) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormatter = DateFormat('MMM yyyy');

    // Generate data points for the last 12 months
    final now = DateTime.now();
    final dataPoints = <MapEntry<String, double>>[];

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      double totalPaid = 0;

      for (final loan in loans) {
        // Calculate total amount paid including past payments
        totalPaid += LoanCalculator.calculateTotalAmountPaid(
          emi: loan.emiAmount,
          monthsPaidSoFar: loan.monthsPaidSoFar,
          amountPaidSoFar: loan.amountPaidSoFar,
          effectiveStartDate: loan.effectiveStartDate,
          status: loan.status,
          closureAmount: loan.closureAmount,
          currentDate: date,
        );
      }

      dataPoints.add(MapEntry(
        dateFormatter.format(date),
        totalPaid,
      ));
    }

    final maxValue = dataPoints.isEmpty
        ? 0.0
        : dataPoints
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repayment Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= dataPoints.length) {
                            return const Text('');
                          }
                          return Text(
                            dataPoints[value.toInt()].key,
                            style: const TextStyle(fontSize: 9),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                        reservedSize: 45,
                        interval: 2,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final formatted = formatter.format(value);
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              formatted,
                              style: const TextStyle(fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          );
                        },
                        reservedSize: 55,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.value,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxValue * 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

