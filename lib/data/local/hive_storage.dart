import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/loan_model.dart';
import '../../core/constants/app_constants.dart';
import 'hive_adapter.dart';

/// Hive storage service for offline data persistence
class HiveStorage {
  static Box<LoanModel>? _loansBox;

  /// Initialize Hive storage with error handling and corruption recovery
  static Future<void> init() async {
    try {
      // Initialize Hive Flutter
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LoanModelAdapter());
      }
      
      // Try to open box
      try {
        _loansBox = await Hive.openBox<LoanModel>(AppConstants.loansBoxName);
      } on RangeError {
        // Corrupted data detected - delete and recreate
        debugPrint('HiveStorage: Corrupted data detected (RangeError). Clearing and recreating box...');
        await _recoverFromCorruption();
        _loansBox = await Hive.openBox<LoanModel>(AppConstants.loansBoxName);
      }
    } catch (e) {
      // Log error but don't throw - allow app to continue
      debugPrint('HiveStorage.init error: $e');
      // Try to recover by deleting corrupted box
      try {
        await _recoverFromCorruption();
        await Hive.initFlutter();
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(LoanModelAdapter());
        }
        _loansBox = await Hive.openBox<LoanModel>(AppConstants.loansBoxName);
      } catch (e2) {
        debugPrint('HiveStorage.init recovery failed: $e2');
        // If still fails, try to create a fresh box
        try {
          // Close any existing box reference
          if (_loansBox != null) {
            await _loansBox!.close();
            _loansBox = null;
          }
          // Delete the box file
          await _deleteBoxFile(AppConstants.loansBoxName);
          // Create fresh box
          _loansBox = await Hive.openBox<LoanModel>(AppConstants.loansBoxName);
        } catch (e3) {
          debugPrint('HiveStorage.init final recovery failed: $e3');
          // If still fails, app will handle null box gracefully
        }
      }
    }
  }

  /// Recover from corrupted Hive box by deleting and recreating
  static Future<void> _recoverFromCorruption() async {
    try {
      // Close box if open
      if (_loansBox != null) {
        await _loansBox!.close();
        _loansBox = null;
      }
      
      // Delete the corrupted box file
      await _deleteBoxFile(AppConstants.loansBoxName);
      
      debugPrint('HiveStorage: Corrupted box deleted. Fresh box will be created.');
    } catch (e) {
      debugPrint('HiveStorage._recoverFromCorruption error: $e');
    }
  }

  /// Delete Hive box file from disk
  static Future<void> _deleteBoxFile(String boxName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final boxPath = '${directory.path}/$boxName.hive';
      final lockPath = '${directory.path}/$boxName.lock';
      
      final boxFile = File(boxPath);
      final lockFile = File(lockPath);
      
      if (await boxFile.exists()) {
        await boxFile.delete();
        debugPrint('HiveStorage: Deleted box file: $boxPath');
      }
      
      if (await lockFile.exists()) {
        await lockFile.delete();
        debugPrint('HiveStorage: Deleted lock file: $lockPath');
      }
    } catch (e) {
      debugPrint('HiveStorage._deleteBoxFile error: $e');
    }
  }

  /// Get loans box
  /// Returns null if not initialized (allows graceful degradation)
  Box<LoanModel>? get loansBox => _loansBox;

  /// Get loans box or throw if not initialized
  Box<LoanModel> get loansBoxOrThrow {
    if (_loansBox == null) {
      throw Exception('HiveStorage not initialized. Call init() first.');
    }
    return _loansBox!;
  }

  /// Get all loans (optimized with lazy loading)
  Future<List<LoanModel>> getAllLoans() async {
    final box = loansBox;
    if (box == null) {
      debugPrint('HiveStorage: Box not initialized, returning empty list');
      return [];
    }
    try {
      // Use lazy list to avoid loading all data at once
      return box.values.toList(growable: false);
    } catch (e) {
      debugPrint('HiveStorage.getAllLoans error: $e');
      return [];
    }
  }

  /// Get loan by ID (optimized - synchronous Hive operation)
  Future<LoanModel?> getLoanById(String id) async {
    final box = loansBox;
    if (box == null) {
      debugPrint('HiveStorage: Box not initialized, returning null');
      return null;
    }
    try {
      // Hive get operation is fast and synchronous
      return box.get(id);
    } catch (e) {
      // Return null on error instead of throwing
      debugPrint('HiveStorage.getLoanById error: $e');
      return null;
    }
  }

  /// Save loan (add or update)
  Future<void> saveLoan(LoanModel loan) async {
    final box = loansBox;
    if (box == null) {
      debugPrint('HiveStorage: Box not initialized, cannot save loan');
      return;
    }
    try {
      await box.put(loan.id, loan);
    } catch (e) {
      debugPrint('HiveStorage.saveLoan error: $e');
      rethrow;
    }
  }

  /// Delete loan
  Future<void> deleteLoan(String id) async {
    final box = loansBox;
    if (box == null) {
      debugPrint('HiveStorage: Box not initialized, cannot delete loan');
      return;
    }
    try {
      await box.delete(id);
    } catch (e) {
      debugPrint('HiveStorage.deleteLoan error: $e');
      rethrow;
    }
  }

  /// Clear all loans
  Future<void> clearAll() async {
    final box = loansBox;
    if (box == null) {
      debugPrint('HiveStorage: Box not initialized, cannot clear');
      return;
    }
    try {
      await box.clear();
    } catch (e) {
      debugPrint('HiveStorage.clearAll error: $e');
      rethrow;
    }
  }
}

