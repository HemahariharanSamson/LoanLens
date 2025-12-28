import '../models/loan_model.dart';
import '../local/hive_storage.dart';
import '../../core/utils/loan_calculator.dart';

/// Repository for loan data operations
class LoanRepository {
  final HiveStorage _storage;

  LoanRepository(this._storage);

  /// Get all loans
  Future<List<LoanModel>> getAllLoans() async {
    return await _storage.getAllLoans();
  }

  /// Get loan by ID
  Future<LoanModel?> getLoanById(String id) async {
    return await _storage.getLoanById(id);
  }

  /// Add a new loan
  Future<void> addLoan(LoanModel loan) async {
    await _storage.saveLoan(loan);
  }

  /// Update an existing loan
  Future<void> updateLoan(LoanModel loan) async {
    await _storage.saveLoan(loan);
  }

  /// Delete a loan
  Future<void> deleteLoan(String id) async {
    await _storage.deleteLoan(id);
  }

  /// Get loan analytics (with past payments and closure support)
  /// Optimized for performance - calculations are synchronous and fast
  Future<LoanAnalytics> getLoanAnalytics(LoanModel loan) async {
    try {
      // All calculations are synchronous and fast - no async operations needed
      // Calculate total payable
      final totalPayable = LoanCalculator.calculateTotalPayable(
        emi: loan.emiAmount,
        tenureMonths: loan.tenureInMonths,
      );
      
      // Calculate total interest
      final totalInterest = LoanCalculator.calculateTotalInterest(
        principal: loan.principalAmount,
        totalPayable: totalPayable,
      );
      
      // Calculate outstanding with history
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
      
      // Calculate total amount paid
      final amountPaid = LoanCalculator.calculateTotalAmountPaid(
        emi: loan.emiAmount,
        monthsPaidSoFar: loan.monthsPaidSoFar,
        amountPaidSoFar: loan.amountPaidSoFar,
        effectiveStartDate: loan.effectiveStartDate,
        status: loan.status,
        closureAmount: loan.closureAmount,
      );
      
      // Calculate total months paid
      final totalPaidMonths = loan.totalMonthsPaid;
      
      return LoanAnalytics(
        totalPayable: totalPayable,
        totalInterest: totalInterest,
        remainingBalance: remainingBalance,
        amountPaid: amountPaid,
        paidMonths: totalPaidMonths,
        totalMonths: loan.tenureInMonths,
      );
    } catch (e) {
      // Return default analytics on error to prevent crashes
      return LoanAnalytics(
        totalPayable: loan.emiAmount * loan.tenureInMonths,
        totalInterest: 0,
        remainingBalance: loan.principalAmount,
        amountPaid: 0,
        paidMonths: 0,
        totalMonths: loan.tenureInMonths,
      );
    }
  }

  /// Get dashboard summary (excluding closed loans from outstanding)
  Future<DashboardSummary> getDashboardSummary() async {
    final loans = await getAllLoans();
    
    double totalOutstanding = 0;
    double totalMonthlyEMI = 0;
    double totalInterestPayable = 0;
    double totalPaid = 0;
    
    // Filter only ongoing loans for outstanding and EMI calculations
    final ongoingLoans = loans.where((loan) => !loan.isClosed).toList();
    
    for (final loan in loans) {
      final analytics = await getLoanAnalytics(loan);
      totalInterestPayable += analytics.totalInterest;
      totalPaid += analytics.amountPaid;
    }
    
    for (final loan in ongoingLoans) {
      final analytics = await getLoanAnalytics(loan);
      totalOutstanding += analytics.remainingBalance;
      totalMonthlyEMI += loan.emiAmount;
    }
    
    return DashboardSummary(
      totalOutstanding: totalOutstanding,
      totalMonthlyEMI: totalMonthlyEMI,
      totalInterestPayable: totalInterestPayable,
      totalLoans: loans.length,
      totalPaid: totalPaid,
      ongoingLoans: ongoingLoans.length,
      closedLoans: loans.length - ongoingLoans.length,
    );
  }
  
  /// Get ongoing loans only
  Future<List<LoanModel>> getOngoingLoans() async {
    final loans = await getAllLoans();
    return loans.where((loan) => !loan.isClosed).toList();
  }
  
  /// Get closed loans only
  Future<List<LoanModel>> getClosedLoans() async {
    final loans = await getAllLoans();
    return loans.where((loan) => loan.isClosed).toList();
  }
}

/// Loan analytics data class
class LoanAnalytics {
  final double totalPayable;
  final double totalInterest;
  final double remainingBalance;
  final double amountPaid;
  final int paidMonths;
  final int totalMonths;

  LoanAnalytics({
    required this.totalPayable,
    required this.totalInterest,
    required this.remainingBalance,
    required this.amountPaid,
    required this.paidMonths,
    required this.totalMonths,
  });

  double get progressPercentage {
    if (totalMonths == 0) return 0;
    return (paidMonths / totalMonths) * 100;
  }
}

/// Dashboard summary data class
class DashboardSummary {
  final double totalOutstanding;
  final double totalMonthlyEMI;
  final double totalInterestPayable;
  final double totalPaid;
  final int totalLoans;
  final int ongoingLoans;
  final int closedLoans;

  DashboardSummary({
    required this.totalOutstanding,
    required this.totalMonthlyEMI,
    required this.totalInterestPayable,
    required this.totalLoans,
    this.totalPaid = 0.0,
    this.ongoingLoans = 0,
    this.closedLoans = 0,
  });
}


