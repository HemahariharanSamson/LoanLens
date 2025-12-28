# Version 3.1.0 - Personalization Feature

## 🎉 Overview

Version 3.1.0 introduces a personalization feature that allows users to set and update their name for a more personalized app experience. The feature is fully offline, optional, and seamlessly integrated into the app.

## ✨ New Features

### 1. User Profile Management
- **UserProfile Model**: New model to store user information (name)
- **Hive Storage**: User profile stored locally using Hive (fully offline)
- **Profile Adapter**: Custom Hive adapter for UserProfile serialization

### 2. Onboarding Experience
- **First Launch Dialog**: Optional name collection dialog on first app launch
- **Skippable**: Users can skip name entry if they prefer
- **Non-Intrusive**: Dialog is dismissible and doesn't block app usage

### 3. Personalized Dashboard
- **Custom Greeting**: Dashboard shows "Hello, [Name]" when name is set
- **Fallback**: Shows "Hello there" when no name is provided
- **Clickable Greeting**: Tap the greeting to update your name anytime

### 4. Profile Management
- **Profile Icon**: New profile icon in app bar for easy access
- **Update Anytime**: Update your name at any point during app session
- **Pre-filled Dialog**: Current name is pre-filled when updating

### 5. Mid-Session Prompts
- **Smart Detection**: App detects if no name is set during session
- **Optional Prompt**: Shows dialog to collect name (non-blocking)
- **Multiple Entry Points**: Update name via profile icon, greeting tap, or automatic prompt

## 📁 New Files

```
lib/
├── data/
│   └── models/
│       └── user_profile.dart          # UserProfile model
├── features/
│   └── onboarding/
│       ├── onboarding_dialog.dart     # Name collection dialog
│       └── onboarding_wrapper.dart    # Onboarding check wrapper
```

## 🔧 Modified Files

1. **lib/data/local/hive_adapter.dart**
   - Added `UserProfileAdapter` (typeId: 1)

2. **lib/data/local/hive_storage.dart**
   - Added user profile box initialization
   - Added `getUserProfile()`, `saveUserProfile()`, `hasCompletedOnboarding()` methods
   - Integrated user profile box in initialization and recovery

3. **lib/core/constants/app_constants.dart**
   - Added `userProfileBoxName` constant

4. **lib/features/dashboard/dashboard_screen.dart**
   - Converted to `ConsumerStatefulWidget` for state management
   - Added `userProfileProvider` for profile state
   - Added personalized greeting display
   - Added profile icon in app bar
   - Added mid-session name check
   - Made greeting clickable

5. **lib/app.dart**
   - Added `OnboardingWrapper` in MaterialApp builder

6. **pubspec.yaml**
   - Version updated to 3.1.0+1

## 🎯 User Experience

### First Launch
1. App opens and shows onboarding dialog
2. User can enter name or skip
3. Profile is saved (even if skipped)
4. Dashboard shows personalized greeting

### During Session
1. If no name is set, dialog appears automatically (dismissible)
2. User can tap profile icon to update name
3. User can tap greeting to update name
4. All updates are saved immediately

### Profile Update
1. Dialog pre-fills current name
2. Title changes to "Update Profile"
3. "Skip" button hidden (only on first launch)
4. Changes saved to local storage

## 🔒 Privacy & Security

- **100% Offline**: All profile data stored locally
- **No Cloud Sync**: No data leaves the device
- **Optional**: Name collection is completely optional
- **Secure Storage**: Uses Hive encryption-ready storage

## ⚡ Performance

- **No Impact**: Personalization feature has zero performance impact
- **Cached Providers**: User profile cached using Riverpod
- **Lazy Loading**: Profile loaded only when needed
- **Optimized Checks**: Onboarding checks are non-blocking

## 🐛 Bug Fixes

- None (new feature release)

## 📊 Statistics

- **Files Changed**: 9 files
- **Lines Added**: 488 insertions
- **Lines Removed**: 9 deletions
- **New Files**: 3 files
- **Modified Files**: 6 files

## 🔄 Migration

No migration needed. Existing users will see the onboarding dialog on next app launch if no name is set.

## 📝 Technical Details

### UserProfile Model
```dart
class UserProfile extends HiveObject {
  String? name;
  bool get hasName => name != null && name!.trim().isNotEmpty;
  String get displayName => hasName ? name!.trim() : 'there';
}
```

### Storage
- Box Name: `user_profile_box`
- Key: `'profile'`
- Type: `UserProfile`

### Providers
- `userProfileProvider`: FutureProvider for user profile state
- Cached for 30 seconds to avoid unnecessary reloads

## 🎨 UI/UX Improvements

- Clean, minimalist onboarding dialog
- Subtle edit icon next to greeting
- Profile icon in app bar (person outline)
- Smooth transitions and animations
- Consistent with app's design language

## 🚀 Future Enhancements

Potential future improvements:
- Profile picture support
- Additional profile fields
- Profile export/import
- Multiple user profiles

## ✅ Testing

- ✅ First launch onboarding works correctly
- ✅ Name update via profile icon works
- ✅ Name update via greeting tap works
- ✅ Mid-session prompt appears when no name set
- ✅ Skip functionality works
- ✅ Profile persists across app restarts
- ✅ Graceful fallback when no name is set
- ✅ No performance degradation

## 📚 Documentation

- Updated README.md with v3.1.0 features
- Created VERSION_3.1.0_SUMMARY.md (this file)
- Code comments added for clarity

---

**Release Date**: December 2024  
**Version**: 3.1.0+1  
**Status**: ✅ Stable

