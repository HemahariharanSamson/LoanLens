# Changelog

All notable changes to LoanLens will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.0] - 2024-12-XX

### 🐛 Fixed
- **Critical:** Fixed data persistence bug where loan details were deleted after closing the app
- Fixed rupee symbol not displaying correctly in PDF reports (now uses "Rs.")

### ✨ Added
- SQLite database migration for reliable data persistence
- Comprehensive error handling and input validation
- SQL injection prevention with parameterized queries
- Transaction support for atomic database operations
- Safe data parsing with fallback values
- Enhanced security measures throughout database layer

### 🔄 Changed
- Migrated from Hive to SQLite (sqflite) for storage
- Updated currency symbol in PDFs from "₹" to "Rs." for better compatibility
- Improved error handling and logging throughout the app

### 🗑️ Removed
- Hive storage implementation (`hive_storage.dart`, `hive_adapter.dart`)
- Hive dependencies from `pubspec.yaml`

### 🔒 Security
- Added parameterized queries to prevent SQL injection
- Added input validation for all database operations
- Added transaction support for data consistency
- Enhanced error handling to prevent data corruption

## [3.1.0] - 2024-XX-XX

### ✨ Added
- Personalization feature with user name collection
- Smart onboarding dialog on first launch
- Mid-session profile updates via profile icon
- PDF sharing for all loans as comprehensive report
- User profile storage with Hive

### 🔄 Changed
- Enhanced dashboard with personalized greetings
- Improved UX with clickable greeting and profile icon

## [3.0.0] - 2024-XX-XX

### 🐛 Fixed
- Fixed splash screen hanging issue
- Resolved Android OnBackInvokedCallback warning
- Optimized loan details screen loading

### ⚡ Performance
- Faster app startup with timeout protection
- Optimized provider caching
- Improved analytics rendering speed

## [2.0.0] - 2024-XX-XX

### ✨ Added
- New modern app icon design
- Enhanced visual identity

## [1.0.0] - 2024-XX-XX

### ✨ Added
- Initial release
- Loan management (CRUD operations)
- Past payments support
- Early closure functionality
- Analytics dashboard with charts
- Local notifications for EMI reminders
- Offline-first architecture

