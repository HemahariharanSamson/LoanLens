import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/loan_repository.dart';
import '../../core/utils/loan_calculator.dart';

/// Service for generating PDF documents
class PdfService {
  // Use 'Rs.' instead of '₹' for better PDF compatibility
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );
  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYearFormatter = DateFormat('MMM yyyy');

  /// Generate PDF for loan details
  static Future<pw.Document> generateLoanDetailsPdf({
    required LoanModel loan,
    required LoanAnalytics analytics,
    UserProfile? userProfile,
  }) async {
    final pdf = pw.Document();
    final formatter = _currencyFormatter;
    final dateFormatter = _dateFormatter;

    // Generate repayment trend data
    final trendData = _generateRepaymentTrendData(loan);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header with user name
            _buildHeader(userProfile),
            pw.SizedBox(height: 20),

            // Loan Information Section
            _buildLoanInfoSection(loan, analytics, formatter, dateFormatter),
            pw.SizedBox(height: 20),

            // Summary Cards
            _buildSummarySection(analytics, formatter),
            pw.SizedBox(height: 20),

            // Repayment Trend Chart
            _buildRepaymentTrendChart(trendData, formatter),
            pw.SizedBox(height: 20),

            // Progress Section
            _buildProgressSection(analytics),
            pw.SizedBox(height: 20),

            // Footer
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Build header with user name
  static pw.Widget _buildHeader(UserProfile? userProfile) {
    final userName = userProfile?.hasName == true
        ? userProfile!.displayName
        : 'User';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Loan Details Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated for $userName',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }

  /// Build loan information section
  static pw.Widget _buildLoanInfoSection(
    LoanModel loan,
    LoanAnalytics analytics,
    NumberFormat formatter,
    DateFormat dateFormatter,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Loan Information',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Loan Name', loan.loanName),
          _buildInfoRow('Lender', loan.lenderName),
          _buildInfoRow('Principal Amount', formatter.format(loan.principalAmount)),
          _buildInfoRow(
            'Interest Rate',
            '${loan.interestRate.toStringAsFixed(2)}% ${loan.interestType}',
          ),
          _buildInfoRow('EMI Amount', formatter.format(loan.emiAmount)),
          _buildInfoRow('Start Date', dateFormatter.format(loan.startDate)),
          _buildInfoRow(
            'Tenure',
            '${loan.tenure} ${loan.tenureUnit} (${loan.tenureInMonths} months)',
          ),
          if (loan.firstEmiDate != null)
            _buildInfoRow(
              'First EMI Date',
              dateFormatter.format(loan.firstEmiDate!),
            ),
          if (loan.monthsPaidSoFar > 0 || loan.amountPaidSoFar > 0) ...[
            pw.Divider(height: 16),
            pw.Text(
              'Past Payments',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildInfoRow(
              'Months Already Paid',
              '${loan.monthsPaidSoFar} months',
            ),
            _buildInfoRow(
              'Amount Paid Before',
              formatter.format(loan.amountPaidSoFar),
            ),
          ],
          if (loan.isClosed) ...[
            pw.Divider(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Loan Status: Closed',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  if (loan.closureDate != null)
                    pw.Text(
                      'Closed on: ${dateFormatter.format(loan.closureDate!)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.green700,
                      ),
                    ),
                  if (loan.closureAmount != null)
                    pw.Text(
                      'Settlement: ${formatter.format(loan.closureAmount!)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.green700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build summary section with key metrics
  static pw.Widget _buildSummarySection(
    LoanAnalytics analytics,
    NumberFormat formatter,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildSummaryCard(
            'Total Payable',
            formatter.format(analytics.totalPayable),
            PdfColors.blue700,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _buildSummaryCard(
            'Total Interest',
            formatter.format(analytics.totalInterest),
            PdfColors.orange700,
          ),
        ),
      ],
    );
  }

  /// Build summary card
  static pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build repayment trend chart (as table for PDF compatibility)
  static pw.Widget _buildRepaymentTrendChart(
    List<MapEntry<String, double>> trendData,
    NumberFormat formatter,
  ) {
    if (trendData.isEmpty) {
      return pw.Container();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Repayment Trend (Last 12 Months)',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Month',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Total Paid',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              // Data rows
              ...trendData.map((entry) {
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        entry.key,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        formatter.format(entry.value),
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Build progress section
  static pw.Widget _buildProgressSection(LoanAnalytics analytics) {
    final progress = analytics.progressPercentage / 100;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Repayment Progress',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              // Progress fill
              pw.Expanded(
                flex: (progress * 100).round(),
                child: pw.Container(
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue700,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                ),
              ),
              // Remaining space
              pw.Expanded(
                flex: ((1 - progress) * 100).round().clamp(0, 100),
                child: pw.Container(
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${analytics.paidMonths} of ${analytics.totalMonths} months completed (${analytics.progressPercentage.toStringAsFixed(1)}%)',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildProgressMetric(
                  'Amount Paid',
                  _currencyFormatter.format(analytics.amountPaid),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildProgressMetric(
                  'Remaining',
                  _currencyFormatter.format(analytics.remainingBalance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build progress metric
  static pw.Widget _buildProgressMetric(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 16),
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated by LoanLens - Your Personal Loan Tracker',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey500,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Generate PDF for all loans (comprehensive report)
  static Future<pw.Document> generateAllLoansPdf({
    required List<LoanModel> loans,
    required LoanRepository repository,
    UserProfile? userProfile,
  }) async {
    final pdf = pw.Document();
    final formatter = _currencyFormatter;
    final dateFormatter = _dateFormatter;

    // Calculate summary data
    double totalOutstanding = 0;
    double totalMonthlyEMI = 0;
    double totalInterestPayable = 0;
    double totalPaid = 0;
    final ongoingLoans = loans.where((loan) => !loan.isClosed).toList();

    for (final loan in loans) {
      final analytics = await repository.getLoanAnalytics(loan);
      totalInterestPayable += analytics.totalInterest;
      totalPaid += analytics.amountPaid;
    }

    for (final loan in ongoingLoans) {
      final analytics = await repository.getLoanAnalytics(loan);
      totalOutstanding += analytics.remainingBalance;
      totalMonthlyEMI += loan.emiAmount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header with user name
            _buildAllLoansHeader(userProfile, loans.length),
            pw.SizedBox(height: 20),

            // Summary Section
            _buildAllLoansSummaryWidget(
              totalOutstanding,
              totalMonthlyEMI,
              totalInterestPayable,
              totalPaid,
              ongoingLoans.length,
              loans.length - ongoingLoans.length,
              formatter,
            ),
            pw.SizedBox(height: 20),

            // All Loans Details
            ..._buildAllLoansDetails(loans, formatter, dateFormatter),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Build header for all loans PDF
  static pw.Widget _buildAllLoansHeader(UserProfile? userProfile, int loanCount) {
    final userName = userProfile?.hasName == true
        ? userProfile!.displayName
        : 'User';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Complete Loan Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated for $userName',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Total Loans: $loanCount',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }

  /// Build summary widget for all loans
  static pw.Widget _buildAllLoansSummaryWidget(
    double totalOutstanding,
    double totalMonthlyEMI,
    double totalInterestPayable,
    double totalPaid,
    int ongoingCount,
    int closedCount,
    NumberFormat formatter,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryCard(
                  'Total Outstanding',
                  formatter.format(totalOutstanding),
                  PdfColors.red700,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildSummaryCard(
                  'Monthly EMI',
                  formatter.format(totalMonthlyEMI),
                  PdfColors.blue700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryCard(
                  'Total Interest',
                  formatter.format(totalInterestPayable),
                  PdfColors.orange700,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildSummaryCard(
                  'Total Paid',
                  formatter.format(totalPaid),
                  PdfColors.green700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Ongoing Loans: $ongoingCount | Closed Loans: $closedCount',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  /// Build details for all loans
  static List<pw.Widget> _buildAllLoansDetails(
    List<LoanModel> loans,
    NumberFormat formatter,
    DateFormat dateFormatter,
  ) {
    final widgets = <pw.Widget>[];

    for (int i = 0; i < loans.length; i++) {
      final loan = loans[i];
      
      // Add spacing between loans (MultiPage handles pagination automatically)
      if (i > 0) {
        widgets.add(pw.SizedBox(height: 20));
      }

      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey400, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${i + 1}. ${loan.loanName}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                loan.lenderName,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Divider(height: 16),
              _buildInfoRow('Principal Amount', formatter.format(loan.principalAmount)),
              _buildInfoRow(
                'Interest Rate',
                '${loan.interestRate.toStringAsFixed(2)}% ${loan.interestType}',
              ),
              _buildInfoRow('EMI Amount', formatter.format(loan.emiAmount)),
              _buildInfoRow('Start Date', dateFormatter.format(loan.startDate)),
              _buildInfoRow(
                'Tenure',
                '${loan.tenure} ${loan.tenureUnit} (${loan.tenureInMonths} months)',
              ),
              if (loan.isClosed) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'Status: Closed',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ),
              ] else
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'Status: Ongoing',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Add footer at the end
    widgets.add(pw.SizedBox(height: 20));
    widgets.add(_buildFooter());

    return widgets;
  }

  /// Build info row
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Generate repayment trend data
  static List<MapEntry<String, double>> _generateRepaymentTrendData(
    LoanModel loan,
  ) {
    final now = DateTime.now();
    final dataPoints = <MapEntry<String, double>>[];

    // Generate data for last 12 months
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final totalPaid = LoanCalculator.calculateTotalAmountPaid(
        emi: loan.emiAmount,
        monthsPaidSoFar: loan.monthsPaidSoFar,
        amountPaidSoFar: loan.amountPaidSoFar,
        effectiveStartDate: loan.effectiveStartDate,
        status: loan.status,
        closureAmount: loan.closureAmount,
        currentDate: date,
      );

      dataPoints.add(MapEntry(
        _monthYearFormatter.format(date),
        totalPaid,
      ));
    }

    return dataPoints;
  }
}


