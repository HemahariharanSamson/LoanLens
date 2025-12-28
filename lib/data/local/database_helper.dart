import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/loan_model.dart';
import '../models/user_profile.dart';

/// SQLite database helper for persistent storage
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('loanlens.db');
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFilePath = path.join(dbPath, filePath);

      return await openDatabase(
        dbFilePath,
        version: 1,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
        singleInstance: true, // Ensure single database instance
      );
    } catch (e) {
      debugPrint('DatabaseHelper._initDB error: $e');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Create loans table
    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        loan_name TEXT NOT NULL,
        lender_name TEXT NOT NULL,
        principal_amount REAL NOT NULL,
        interest_rate REAL NOT NULL,
        interest_type TEXT NOT NULL,
        emi_amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        tenure INTEGER NOT NULL,
        tenure_unit TEXT NOT NULL,
        payment_frequency TEXT NOT NULL DEFAULT 'Monthly',
        notifications_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_days_before INTEGER NOT NULL DEFAULT 1,
        months_paid_so_far INTEGER NOT NULL DEFAULT 0,
        amount_paid_so_far REAL NOT NULL DEFAULT 0,
        first_emi_date TEXT,
        status TEXT NOT NULL DEFAULT 'ongoing',
        closure_date TEXT,
        closure_amount REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create user_profile table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    debugPrint('DatabaseHelper: Tables created successfully');
  }

  /// Handle database upgrades (future migrations)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here if needed in future versions
    debugPrint('DatabaseHelper: Database upgrade from $oldVersion to $newVersion');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('DatabaseHelper: Database closed');
  }

  // ==================== LOAN OPERATIONS ====================

  /// Insert or update a loan
  Future<void> insertOrUpdateLoan(LoanModel loan) async {
    try {
      final db = await database;
      await db.insert(
        'loans',
        _loanToMap(loan),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('DatabaseHelper: Loan saved: ${loan.id}');
    } catch (e) {
      debugPrint('DatabaseHelper.insertOrUpdateLoan error: $e');
      rethrow;
    }
  }

  /// Get all loans
  Future<List<LoanModel>> getAllLoans() async {
    try {
      final db = await database;
      final result = await db.query('loans', orderBy: 'created_at DESC');
      return result.map((map) => _loanFromMap(map)).toList();
    } catch (e) {
      debugPrint('DatabaseHelper.getAllLoans error: $e');
      rethrow;
    }
  }

  /// Get loan by ID
  Future<LoanModel?> getLoanById(String id) async {
    try {
      if (id.isEmpty) {
        debugPrint('DatabaseHelper.getLoanById: Empty ID provided');
        return null;
      }
      final db = await database;
      final result = await db.query(
        'loans',
        where: 'id = ?',
        whereArgs: [id], // Parameterized query prevents SQL injection
        limit: 1,
      );
      if (result.isEmpty) return null;
      return _loanFromMap(result.first);
    } catch (e) {
      debugPrint('DatabaseHelper.getLoanById error: $e');
      return null; // Return null on error instead of throwing
    }
  }

  /// Delete loan by ID
  Future<void> deleteLoan(String id) async {
    try {
      if (id.isEmpty) {
        debugPrint('DatabaseHelper.deleteLoan: Empty ID provided');
        throw ArgumentError('Loan ID cannot be empty');
      }
      final db = await database;
      final deleted = await db.delete(
        'loans',
        where: 'id = ?',
        whereArgs: [id], // Parameterized query prevents SQL injection
      );
      if (deleted > 0) {
        debugPrint('DatabaseHelper: Loan deleted: $id');
      } else {
        debugPrint('DatabaseHelper: No loan found with ID: $id');
      }
    } catch (e) {
      debugPrint('DatabaseHelper.deleteLoan error: $e');
      rethrow;
    }
  }

  /// Clear all loans (use with caution)
  Future<void> clearAllLoans() async {
    try {
      final db = await database;
      final deleted = await db.delete('loans');
      debugPrint('DatabaseHelper: All loans cleared ($deleted records)');
    } catch (e) {
      debugPrint('DatabaseHelper.clearAllLoans error: $e');
      rethrow;
    }
  }

  /// Convert LoanModel to Map for database storage
  Map<String, dynamic> _loanToMap(LoanModel loan) {
    return {
      'id': loan.id,
      'loan_name': loan.loanName,
      'lender_name': loan.lenderName,
      'principal_amount': loan.principalAmount,
      'interest_rate': loan.interestRate,
      'interest_type': loan.interestType,
      'emi_amount': loan.emiAmount,
      'start_date': loan.startDate.toIso8601String(),
      'tenure': loan.tenure,
      'tenure_unit': loan.tenureUnit,
      'payment_frequency': loan.paymentFrequency,
      'notifications_enabled': loan.notificationsEnabled ? 1 : 0,
      'reminder_days_before': loan.reminderDaysBefore,
      'months_paid_so_far': loan.monthsPaidSoFar,
      'amount_paid_so_far': loan.amountPaidSoFar,
      'first_emi_date': loan.firstEmiDate?.toIso8601String(),
      'status': loan.status,
      'closure_date': loan.closureDate?.toIso8601String(),
      'closure_amount': loan.closureAmount,
      'created_at': loan.createdAt.toIso8601String(),
      'updated_at': loan.updatedAt.toIso8601String(),
    };
  }

  /// Convert Map from database to LoanModel
  /// Includes error handling for data validation
  LoanModel _loanFromMap(Map<String, dynamic> map) {
    try {
      return LoanModel(
        id: map['id'] as String? ?? '',
        loanName: map['loan_name'] as String? ?? '',
        lenderName: map['lender_name'] as String? ?? '',
        principalAmount: (map['principal_amount'] as num?)?.toDouble() ?? 0.0,
        interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0.0,
        interestType: map['interest_type'] as String? ?? 'Simple',
        emiAmount: (map['emi_amount'] as num?)?.toDouble() ?? 0.0,
        startDate: _parseDateTime(map['start_date'] as String?),
        tenure: map['tenure'] as int? ?? 0,
        tenureUnit: map['tenure_unit'] as String? ?? 'Months',
        paymentFrequency: map['payment_frequency'] as String? ?? 'Monthly',
        notificationsEnabled: (map['notifications_enabled'] as int?) == 1,
        reminderDaysBefore: map['reminder_days_before'] as int? ?? 1,
        monthsPaidSoFar: map['months_paid_so_far'] as int? ?? 0,
        amountPaidSoFar: (map['amount_paid_so_far'] as num?)?.toDouble() ?? 0.0,
        firstEmiDate: map['first_emi_date'] != null
            ? _parseDateTime(map['first_emi_date'] as String?)
            : null,
        status: map['status'] as String? ?? 'ongoing',
        closureDate: map['closure_date'] != null
            ? _parseDateTime(map['closure_date'] as String?)
            : null,
        closureAmount: map['closure_amount'] != null
            ? (map['closure_amount'] as num).toDouble()
            : null,
        createdAt: _parseDateTime(map['created_at'] as String?),
        updatedAt: _parseDateTime(map['updated_at'] as String?),
      );
    } catch (e) {
      debugPrint('DatabaseHelper._loanFromMap error: $e');
      debugPrint('Failed to parse loan data: $map');
      rethrow;
    }
  }

  /// Safely parse DateTime from ISO8601 string
  DateTime _parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now(); // Fallback to current time
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      debugPrint('DatabaseHelper._parseDateTime error: $e for string: $dateString');
      return DateTime.now(); // Fallback to current time
    }
  }

  // ==================== USER PROFILE OPERATIONS ====================

  /// Save or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final db = await database;
      
      // Use transaction for atomic operation
      await db.transaction((txn) async {
        // Check if profile exists
        final existing = await txn.query('user_profile', limit: 1);
        
        if (existing.isEmpty) {
          // Insert new profile
          await txn.insert(
            'user_profile',
            {'name': profile.name},
          );
        } else {
          // Update existing profile
          await txn.update(
            'user_profile',
            {'name': profile.name},
            where: 'id = ?',
            whereArgs: [existing.first['id']], // Parameterized query
          );
        }
      });
      debugPrint('DatabaseHelper: User profile saved');
    } catch (e) {
      debugPrint('DatabaseHelper.saveUserProfile error: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final db = await database;
      final result = await db.query('user_profile', limit: 1);
      if (result.isEmpty) return null;
      
      return UserProfile(
        name: result.first['name'] as String?,
      );
    } catch (e) {
      debugPrint('DatabaseHelper.getUserProfile error: $e');
      return null; // Return null on error
    }
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    final profile = await getUserProfile();
    return profile != null && profile.hasName;
  }
}

