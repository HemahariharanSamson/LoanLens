# Data Persistence Issue - Root Cause Analysis

## 🔍 Problem
Loan details are deleted after closing the app. Data entered by the user disappears when the app is reopened.

## 🔬 Root Cause Identified

### **PRIMARY ISSUE: `Hive.initFlutter()` Called Multiple Times**

**Location:** `lib/data/local/hive_storage.dart`, line 25

**Problem:**
```dart
await Hive.initFlutter();  // Line 25 - Called EVERY time init() runs
```

**Explanation:**
- `Hive.initFlutter()` should ONLY be called ONCE in the entire app lifecycle
- Currently, it's called every time `HiveStorage.init()` runs
- Even though there's a check at line 19 to skip if boxes are initialized, `Hive.initFlutter()` is called BEFORE that check
- Calling `Hive.initFlutter()` multiple times can:
  - Reset Hive's internal state
  - Change the storage directory
  - Cause boxes to lose connection to their data files
  - Result in data being saved to a different location or not persisted

### **SECONDARY ISSUE: Timeout in main.dart Swallows Errors**

**Location:** `lib/main.dart`, lines 15-24

**Problem:**
```dart
HiveStorage.init().timeout(
  const Duration(seconds: 3),
  onTimeout: () {
    debugPrint('Warning: Hive initialization timed out after 3 seconds');
    return;  // Just returns void - doesn't throw
  },
).catchError((e) {
  debugPrint('Error initializing Hive: $e');
  return;  // Swallows the error
}),
```

**Explanation:**
- If initialization times out or fails, the error is swallowed
- The app continues running even though boxes might not be initialized
- This means `_loansBox` and `_userProfileBox` could be null
- Data saves would fail silently, appearing to work but not actually persisting

### **TERTIARY ISSUE: Check for Initialization is After Hive.initFlutter()**

**Location:** `lib/data/local/hive_storage.dart`, lines 18-25

**Problem:**
```dart
// Check if already initialized
if (_loansBox != null && _userProfileBox != null) {
  return;  // Only returns here if BOTH boxes are initialized
}

// Initialize Hive Flutter - CALLED EVERY TIME!
await Hive.initFlutter();  // This is the problem!
```

**Explanation:**
- The check for already-initialized boxes comes AFTER any potential `Hive.initFlutter()` calls
- Even if boxes are already open, `Hive.initFlutter()` might be called in error recovery paths (line 65)
- This can cause Hive to reset its state even when boxes exist

## 📋 Detailed Analysis

### File: `lib/data/local/hive_storage.dart`

**Lines 16-89 (init method):**
1. ✅ Has check to skip if already initialized (line 19)
2. ❌ **BUG:** Calls `Hive.initFlutter()` at line 25 - should only be called once
3. ❌ **BUG:** Calls `Hive.initFlutter()` again at line 65 in recovery path
4. ✅ Has proper error handling for corruption (RangeError only)
5. ✅ Has flush() calls to persist data

**Lines 178-208 (saveLoan method):**
1. ✅ Has flush() call to persist data immediately
2. ✅ Has retry logic if box is null
3. ❌ **POTENTIAL ISSUE:** If box is null and init() fails, data won't be saved

### File: `lib/main.dart`

**Lines 15-24:**
1. ❌ **BUG:** Timeout handler returns void instead of preserving error state
2. ❌ **BUG:** catchError swallows all errors
3. ❌ **RESULT:** App continues even if Hive initialization fails
4. ❌ **RESULT:** Boxes might be null but app doesn't know

### File: `lib/data/repositories/loan_repository.dart`

**Analysis:**
- ✅ Correctly uses HiveStorage instance
- ✅ All methods properly await storage operations
- ✅ No issues found here

### File: `lib/data/local/hive_adapter.dart`

**Analysis:**
- ✅ Adapter correctly implements read/write
- ✅ TypeId 0 for LoanModel, TypeId 1 for UserProfile
- ✅ Proper null handling for optional fields
- ✅ No issues found here

## 🎯 The Actual Flow (What's Happening)

### On First Launch:
1. `main()` calls `HiveStorage.init()`
2. `Hive.initFlutter()` is called (OK - first time)
3. Boxes are opened successfully
4. User adds loans - data is saved

### On App Close:
1. App closes
2. Static variables `_loansBox` and `_userProfileBox` are lost (but data should be on disk)
3. No explicit close() is called (this is OK - Hive handles it)

### On App Reopen:
1. `main()` calls `HiveStorage.init()` again
2. ❌ **BUG:** `Hive.initFlutter()` is called AGAIN (line 25)
3. This can reset Hive's state or change storage location
4. When boxes are opened, they might open in a different location or with corrupted state
5. Result: Old data files are not found, or boxes are opened fresh

## 🔧 Required Fixes

### Fix 1: Only call Hive.initFlutter() once
- Check if Hive is already initialized before calling `Hive.initFlutter()`
- Use a static flag to track if Hive has been initialized
- Only call `Hive.initFlutter()` if it hasn't been called before

### Fix 2: Fix timeout handling in main.dart
- Don't swallow errors - let them propagate or handle properly
- Ensure boxes are initialized before app starts
- Add proper error state checking

### Fix 3: Ensure boxes persist across app restarts
- Verify boxes are opened from the same location
- Ensure adapter registration happens before box opening
- Add verification that boxes contain data after opening

## 📊 Evidence Supporting This Theory

1. **Data disappears after app close** - Suggests data isn't being read from the same location on restart
2. **No explicit close() calls** - Not necessary, but `Hive.initFlutter()` being called multiple times is the issue
3. **Timeout handling swallows errors** - Means initialization failures are silent
4. **Multiple HiveStorage instances** - Not the issue since boxes are static, but `Hive.initFlutter()` is the problem

## ✅ Verification Steps

To verify this is the issue:
1. Check logs for "Hive initialization timed out" messages
2. Check if `HiveStorage.init()` is being called multiple times
3. Verify the storage directory path is consistent
4. Check if box files exist on disk after closing app

## 🎯 Conclusion

**Root Cause:** `Hive.initFlutter()` is being called multiple times, which can reset Hive's internal state and cause boxes to lose connection to their data files. Combined with error swallowing in `main.dart`, this results in data appearing to save but not persisting across app restarts.

