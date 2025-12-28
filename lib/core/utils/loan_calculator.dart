import 'dart:math';

/// Utility class for loan calculations
class LoanCalculator {
  /// Calculate EMI (Equated Monthly Installment)
  /// Formula: EMI = [P x R x (1+R)^N] / [(1+R)^N - 1]
  /// Where P = Principal, R = Monthly Interest Rate, N = Number of months
  static double calculateEMI({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    if (principal <= 0 || tenureMonths <= 0) return 0;
    
    final monthlyRate = annualInterestRate / 12 / 100;
    if (monthlyRate == 0) {
      return principal / tenureMonths;
    }
    
    final emi = (principal * monthlyRate * pow(1 + monthlyRate, tenureMonths)) /
        (pow(1 + monthlyRate, tenureMonths) - 1);
    
    return emi;
  }
  
  /// Calculate total payable amount (Principal + Total Interest)
  static double calculateTotalPayable({
    required double emi,
    required int tenureMonths,
  }) {
    return emi * tenureMonths;
  }
  
  /// Calculate total interest payable
  static double calculateTotalInterest({
    required double principal,
    required double totalPayable,
  }) {
    return totalPayable - principal;
  }
  
  /// Calculate remaining balance after N payments
  /// Formula for remaining balance: P * [(1+R)^N - (1+R)^n] / [(1+R)^N - 1]
  /// Where P = Principal, R = Monthly Rate, N = Total months, n = Paid months
  static double calculateRemainingBalance({
    required double principal,
    required double annualInterestRate,
    required int totalTenureMonths,
    required int paidMonths,
  }) {
    if (paidMonths >= totalTenureMonths) return 0;
    if (principal <= 0 || totalTenureMonths <= 0) return principal;
    
    final monthlyRate = annualInterestRate / 12 / 100;
    if (monthlyRate == 0) {
      return principal * (1 - (paidMonths / totalTenureMonths));
    }
    
    final remaining = principal *
        (pow(1 + monthlyRate, totalTenureMonths) - pow(1 + monthlyRate, paidMonths)) /
        (pow(1 + monthlyRate, totalTenureMonths) - 1);
    
    return remaining > 0 ? remaining : 0;
  }
  
  /// Calculate amount paid so far
  static double calculateAmountPaid({
    required double emi,
    required int paidMonths,
  }) {
    return emi * paidMonths;
  }
  
  /// Calculate number of months paid based on start date
  static int calculatePaidMonths({
    required DateTime startDate,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    if (now.isBefore(startDate)) return 0;
    
    int months = (now.year - startDate.year) * 12 + (now.month - startDate.month);
    
    // If current day is before start day, don't count current month
    if (now.day < startDate.day) {
      months--;
    }
    
    return months > 0 ? months : 0;
  }
  
  /// Calculate outstanding amount (remaining balance)
  static double calculateOutstanding({
    required double principal,
    required double annualInterestRate,
    required int totalTenureMonths,
    required DateTime startDate,
    DateTime? currentDate,
  }) {
    final paidMonths = calculatePaidMonths(
      startDate: startDate,
      currentDate: currentDate,
    );
    
    return calculateRemainingBalance(
      principal: principal,
      annualInterestRate: annualInterestRate,
      totalTenureMonths: totalTenureMonths,
      paidMonths: paidMonths,
    );
  }
  
  /// Calculate outstanding with past payments and closure
  static double calculateOutstandingWithHistory({
    required double principal,
    required double annualInterestRate,
    required int totalTenureMonths,
    required int monthsPaidSoFar,
    required double amountPaidSoFar,
    required DateTime effectiveStartDate,
    required String status,
    double? closureAmount,
    DateTime? currentDate,
  }) {
    // If closed, return 0 (no outstanding)
    if (status == 'closed') {
      return 0;
    }
    
    // Calculate current months paid from effective start date
    final currentMonthsPaid = calculatePaidMonths(
      startDate: effectiveStartDate,
      currentDate: currentDate,
    );
    
    // Total months paid = past payments + current months
    final totalPaidMonths = monthsPaidSoFar + currentMonthsPaid;
    
    // Calculate remaining balance
    return calculateRemainingBalance(
      principal: principal,
      annualInterestRate: annualInterestRate,
      totalTenureMonths: totalTenureMonths,
      paidMonths: totalPaidMonths,
    );
  }
  
  /// Calculate total amount paid including past payments
  static double calculateTotalAmountPaid({
    required double emi,
    required int monthsPaidSoFar,
    required double amountPaidSoFar,
    required DateTime effectiveStartDate,
    required String status,
    double? closureAmount,
    DateTime? currentDate,
  }) {
    // If closed, return closure amount or total paid
    if (status == 'closed' && closureAmount != null) {
      return closureAmount;
    }
    
    // Calculate current months paid
    final currentMonthsPaid = calculatePaidMonths(
      startDate: effectiveStartDate,
      currentDate: currentDate,
    );
    
    // Total = past payments + current EMI payments
    return amountPaidSoFar + (emi * currentMonthsPaid);
  }
  
  /// Calculate remaining months for ongoing loans
  static int calculateRemainingMonths({
    required int totalTenureMonths,
    required int monthsPaidSoFar,
    required DateTime effectiveStartDate,
    required String status,
    DateTime? currentDate,
  }) {
    if (status == 'closed') {
      return 0;
    }
    
    final currentMonthsPaid = calculatePaidMonths(
      startDate: effectiveStartDate,
      currentDate: currentDate,
    );
    
    final totalPaidMonths = monthsPaidSoFar + currentMonthsPaid;
    final remaining = totalTenureMonths - totalPaidMonths;
    
    return remaining > 0 ? remaining : 0;
  }
}

