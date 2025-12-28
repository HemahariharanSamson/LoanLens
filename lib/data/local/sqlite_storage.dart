import 'package:flutter/foundation.dart';
import '../models/loan_model.dart';
import '../models/user_profile.dart';
import 'database_helper.dart';

/// SQLite storage service - replacement for HiveStorage
/// Provides persistent, fast, and reliable data storage
class SqliteStorage {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Initialize storage (ensures database is ready)
  Future<void> init() async {
    try {
      await _db.database; // Initialize database connection
      debugPrint('SqliteStorage: Initialized successfully');
    } catch (e) {
      debugPrint('SqliteStorage.init error: $e');
      rethrow;
    }
  }

  // ==================== LOAN OPERATIONS ====================

  /// Get all loans
  Future<List<LoanModel>> getAllLoans() async {
    try {
      return await _db.getAllLoans();
    } catch (e) {
      debugPrint('SqliteStorage.getAllLoans error: $e');
      return [];
    }
  }

  /// Get loan by ID
  Future<LoanModel?> getLoanById(String id) async {
    try {
      return await _db.getLoanById(id);
    } catch (e) {
      debugPrint('SqliteStorage.getLoanById error: $e');
      return null;
    }
  }

  /// Save loan (insert or update)
  Future<void> saveLoan(LoanModel loan) async {
    try {
      final updatedLoan = loan.copyWith(updatedAt: DateTime.now());
      await _db.insertOrUpdateLoan(updatedLoan);
      debugPrint('SqliteStorage: Loan saved successfully: ${loan.id}');
    } catch (e) {
      debugPrint('SqliteStorage.saveLoan error: $e');
      rethrow;
    }
  }

  /// Delete loan
  Future<void> deleteLoan(String id) async {
    try {
      await _db.deleteLoan(id);
      debugPrint('SqliteStorage: Loan deleted: $id');
    } catch (e) {
      debugPrint('SqliteStorage.deleteLoan error: $e');
      rethrow;
    }
  }

  /// Clear all loans
  Future<void> clearAll() async {
    try {
      await _db.clearAllLoans();
      debugPrint('SqliteStorage: All loans cleared');
    } catch (e) {
      debugPrint('SqliteStorage.clearAll error: $e');
      rethrow;
    }
  }

  // ==================== USER PROFILE OPERATIONS ====================

  /// Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      return await _db.getUserProfile();
    } catch (e) {
      debugPrint('SqliteStorage.getUserProfile error: $e');
      return null;
    }
  }

  /// Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _db.saveUserProfile(profile);
      debugPrint('SqliteStorage: User profile saved successfully');
    } catch (e) {
      debugPrint('SqliteStorage.saveUserProfile error: $e');
      rethrow;
    }
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      return await _db.hasCompletedOnboarding();
    } catch (e) {
      debugPrint('SqliteStorage.hasCompletedOnboarding error: $e');
      return false;
    }
  }
}

