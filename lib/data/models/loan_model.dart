import 'package:uuid/uuid.dart';
import '../../core/utils/loan_calculator.dart';

/// Loan data model
class LoanModel {
  final String id;
  String loanName;
  String lenderName;
  double principalAmount;
  double interestRate; // Annual percentage
  String interestType; // Simple or Compound
  double emiAmount;
  DateTime startDate;
  int tenure; // Number of months or years
  String tenureUnit; // Months or Years
  String paymentFrequency; // Monthly
  bool notificationsEnabled;
  int reminderDaysBefore; // Days before EMI due date
  DateTime createdAt;
  DateTime updatedAt;
  
  // Past payments and closure fields
  int monthsPaidSoFar; // Months already paid
  double amountPaidSoFar; // Total amount paid so far
  DateTime? firstEmiDate; // Date of first EMI (if different from startDate)
  String status; // 'ongoing' or 'closed'
  DateTime? closureDate; // Date when loan was closed
  double? closureAmount; // Final settlement amount
  
  LoanModel({
    String? id,
    required this.loanName,
    required this.lenderName,
    required this.principalAmount,
    required this.interestRate,
    required this.interestType,
    required this.emiAmount,
    required this.startDate,
    required this.tenure,
    required this.tenureUnit,
    this.paymentFrequency = 'Monthly',
    this.notificationsEnabled = true,
    this.reminderDaysBefore = 1,
    this.monthsPaidSoFar = 0,
    this.amountPaidSoFar = 0.0,
    this.firstEmiDate,
    this.status = 'ongoing',
    this.closureDate,
    this.closureAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// Get tenure in months
  int get tenureInMonths {
    if (tenureUnit == 'Years') {
      return tenure * 12;
    }
    return tenure;
  }
  
  /// Check if loan is closed
  bool get isClosed => status == 'closed';
  
  /// Get effective start date (firstEmiDate if available, otherwise startDate)
  DateTime get effectiveStartDate => firstEmiDate ?? startDate;
  
  /// Get total months paid (including past payments)
  /// Optimized to avoid blocking calculations
  int get totalMonthsPaid {
    if (isClosed) {
      return tenureInMonths; // All months paid if closed
    }
    try {
      final currentMonths = LoanCalculator.calculatePaidMonths(
        startDate: effectiveStartDate,
      );
      return monthsPaidSoFar + currentMonths;
    } catch (e) {
      // Fallback to monthsPaidSoFar if calculation fails
      return monthsPaidSoFar;
    }
  }
  
  /// Create a copy with updated fields
  LoanModel copyWith({
    String? id,
    String? loanName,
    String? lenderName,
    double? principalAmount,
    double? interestRate,
    String? interestType,
    double? emiAmount,
    DateTime? startDate,
    int? tenure,
    String? tenureUnit,
    String? paymentFrequency,
    bool? notificationsEnabled,
    int? reminderDaysBefore,
    int? monthsPaidSoFar,
    double? amountPaidSoFar,
    DateTime? firstEmiDate,
    String? status,
    DateTime? closureDate,
    double? closureAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      loanName: loanName ?? this.loanName,
      lenderName: lenderName ?? this.lenderName,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      interestType: interestType ?? this.interestType,
      emiAmount: emiAmount ?? this.emiAmount,
      startDate: startDate ?? this.startDate,
      tenure: tenure ?? this.tenure,
      tenureUnit: tenureUnit ?? this.tenureUnit,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      monthsPaidSoFar: monthsPaidSoFar ?? this.monthsPaidSoFar,
      amountPaidSoFar: amountPaidSoFar ?? this.amountPaidSoFar,
      firstEmiDate: firstEmiDate ?? this.firstEmiDate,
      status: status ?? this.status,
      closureDate: closureDate ?? this.closureDate,
      closureAmount: closureAmount ?? this.closureAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  /// Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loanName': loanName,
      'lenderName': lenderName,
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'interestType': interestType,
      'emiAmount': emiAmount,
      'startDate': startDate.toIso8601String(),
      'tenure': tenure,
      'tenureUnit': tenureUnit,
      'paymentFrequency': paymentFrequency,
      'notificationsEnabled': notificationsEnabled,
      'reminderDaysBefore': reminderDaysBefore,
      'monthsPaidSoFar': monthsPaidSoFar,
      'amountPaidSoFar': amountPaidSoFar,
      'firstEmiDate': firstEmiDate?.toIso8601String(),
      'status': status,
      'closureDate': closureDate?.toIso8601String(),
      'closureAmount': closureAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// Create from Map
  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'] as String,
      loanName: map['loanName'] as String,
      lenderName: map['lenderName'] as String,
      principalAmount: (map['principalAmount'] as num).toDouble(),
      interestRate: (map['interestRate'] as num).toDouble(),
      interestType: map['interestType'] as String,
      emiAmount: (map['emiAmount'] as num).toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      tenure: map['tenure'] as int,
      tenureUnit: map['tenureUnit'] as String,
      paymentFrequency: map['paymentFrequency'] as String? ?? 'Monthly',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 1,
      monthsPaidSoFar: map['monthsPaidSoFar'] as int? ?? 0,
      amountPaidSoFar: (map['amountPaidSoFar'] as num?)?.toDouble() ?? 0.0,
      firstEmiDate: map['firstEmiDate'] != null 
          ? DateTime.parse(map['firstEmiDate'] as String) 
          : null,
      status: map['status'] as String? ?? 'ongoing',
      closureDate: map['closureDate'] != null 
          ? DateTime.parse(map['closureDate'] as String) 
          : null,
      closureAmount: map['closureAmount'] != null 
          ? (map['closureAmount'] as num).toDouble() 
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

