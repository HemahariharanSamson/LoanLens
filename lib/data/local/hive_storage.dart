import 'package:hive_flutter/hive_flutter.dart';
import '../models/loan_model.dart';
import '../../core/constants/app_constants.dart';
import 'hive_adapter.dart';

/// Hive storage service for offline data persistence
class HiveStorage {
  static Box<LoanModel>? _loansBox;

  /// Initialize Hive storage
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LoanModelAdapter());
    }
    
    // Open boxes
    _loansBox = await Hive.openBox<LoanModel>(AppConstants.loansBoxName);
  }

  /// Get loans box
  Box<LoanModel> get loansBox {
    if (_loansBox == null) {
      throw Exception('HiveStorage not initialized. Call init() first.');
    }
    return _loansBox!;
  }

  /// Get all loans
  Future<List<LoanModel>> getAllLoans() async {
    return loansBox.values.toList();
  }

  /// Get loan by ID
  Future<LoanModel?> getLoanById(String id) async {
    return loansBox.get(id);
  }

  /// Save loan (add or update)
  Future<void> saveLoan(LoanModel loan) async {
    await loansBox.put(loan.id, loan);
  }

  /// Delete loan
  Future<void> deleteLoan(String id) async {
    await loansBox.delete(id);
  }

  /// Clear all loans
  Future<void> clearAll() async {
    await loansBox.clear();
  }
}

