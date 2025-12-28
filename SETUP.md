# LoanLens - Setup Guide

## 📱 About LoanLens

LoanLens is a fully offline-first Flutter mobile application that helps users track and analyze multiple loans they are repaying. The app works 100% offline with no backend, cloud, or login required.

## ✨ Features

- **Loan Management**: Add, edit, and delete multiple loans
- **Past Payments Support**: Add existing loans with payment history
- **Early Closure**: Close loans early with settlement tracking
- **Analytics Dashboard**: Visual charts showing loan distribution, EMI comparison, and repayment trends
- **Local Notifications**: Monthly EMI reminders
- **Offline Storage**: All data stored locally using Hive
- **Dark/Light Mode**: Automatic theme switching (currently set to light mode)

## 🛠️ Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (latest stable version)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Android Studio** or **VS Code** with Flutter extensions
   - Android Studio: https://developer.android.com/studio
   - VS Code: https://code.visualstudio.com/

3. **Android SDK** (for Android development)
   - Included with Android Studio
   - Set `ANDROID_HOME` environment variable

4. **Java Development Kit (JDK)**
   - JDK 11 or higher
   - Download from: https://adoptium.net/

5. **Git** (for version control)
   - Download from: https://git-scm.com/downloads

## 📦 Installation Steps

### 1. Clone the Repository

```bash
git clone <your-github-repo-url>
cd LoanTracker
```

### 2. Install Dependencies

```bash
flutter pub get
```

This will install all required packages listed in `pubspec.yaml`:
- `flutter_riverpod` - State management
- `hive` & `hive_flutter` - Offline storage
- `fl_chart` - Charts and visualizations
- `flutter_local_notifications` - Local notifications
- `intl` - Internationalization
- `uuid` - Unique ID generation
- And more...

### 3. Android Configuration

The app is pre-configured with:
- NDK version: 27.0.12077973
- Core library desugaring enabled
- Notification permissions in AndroidManifest.xml

No additional Android configuration needed.

### 4. Run the App

#### On Android Device/Emulator:

```bash
flutter run
```

#### On Specific Device:

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

#### Build APK:

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

## 🚀 First Run

1. **Launch the app** on your device/emulator
2. **Grant permissions** when prompted:
   - Notification permissions (for EMI reminders)
3. **Add your first loan**:
   - Tap the "+ Add Loan" button
   - Fill in loan details
   - Optionally check "Already repaying this loan?" to add past payments
4. **View dashboard** to see your loan overview
5. **Explore analytics** via the chart icon in the app bar

## 📖 Usage Guide

### Adding a New Loan

1. Tap the **"+ Add Loan"** floating action button
2. Fill in the required fields:
   - Loan Name (e.g., "Home Loan")
   - Lender Name (e.g., "HDFC Bank")
   - Principal Amount
   - Interest Rate (%)
   - Interest Type (Simple/Compound)
   - EMI Amount (or enable auto-calculation)
   - Tenure (Months/Years)
   - Start Date
3. **Optional - Past Payments**:
   - Check "Already repaying this loan?"
   - Enter months already paid
   - Enter total amount paid so far
   - Select first EMI date (optional)
4. Configure notifications (optional)
5. Tap **"Save Loan"**

### Editing a Loan

1. Open the loan from the dashboard
2. Tap the **edit icon** in the app bar
3. Modify the fields as needed
4. Tap **"Save Loan"**

### Closing a Loan Early

1. Open the loan details screen
2. Scroll to the bottom
3. Tap **"Close Loan Early"** button
4. Enter the settlement amount
5. Confirm the closure

### Viewing Analytics

1. Tap the **analytics icon** (chart) in the dashboard app bar
2. View three types of charts:
   - **Outstanding Distribution** (Pie Chart)
   - **Monthly EMI Comparison** (Bar Chart)
   - **Repayment Trend** (Line Chart)

### Managing Notifications

- Notifications are enabled by default for new loans
- Configure reminder days before EMI due date
- Notifications are automatically canceled for closed loans
- Disable notifications per loan in the edit screen

## 🗂️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # Main app widget with routing
├── core/
│   ├── constants/              # App constants
│   ├── theme/                   # Light/dark themes
│   ├── utils/                   # Calculation utilities
│   └── services/                # Notification service
├── data/
│   ├── models/                  # Loan data model
│   ├── repositories/            # Data repository
│   └── local/                   # Hive storage & adapter
├── features/
│   ├── dashboard/               # Dashboard screen
│   ├── loans/                   # Add/Edit/Details screens
│   └── analytics/               # Charts & analytics
├── widgets/                     # Reusable UI components
└── routes/                      # Route definitions
```

## 🔧 Troubleshooting

### Build Errors

**Issue**: NDK version mismatch
```bash
# Already configured in build.gradle.kts
# If issues persist, check Android Studio SDK Manager
```

**Issue**: Core library desugaring error
```bash
# Already enabled in build.gradle.kts
# Ensure desugar_jdk_libs dependency is present
```

### Notification Issues

**Issue**: Notifications not working
- Check app notification permissions in device settings
- Ensure notifications are enabled for the loan
- Verify timezone is set correctly

### Data Issues

**Issue**: Data not persisting
- Check Hive initialization in main.dart
- Verify storage permissions on device
- Clear app data and reinstall if needed

### Flutter Issues

**Issue**: `flutter pub get` fails
```bash
# Clean and retry
flutter clean
flutter pub get
```

**Issue**: Build fails
```bash
# Clean build
flutter clean
flutter pub get
flutter run
```

## 📱 Platform Support

- ✅ **Android** (Primary - Fully tested)
- ✅ **iOS** (Compatible - may need iOS-specific configuration)

## 🔐 Privacy & Security

- **100% Offline**: No data leaves your device
- **No Backend**: No cloud storage or servers
- **No Login**: No authentication required
- **Local Storage**: All data stored in device storage using Hive

## 📝 Version Information

- **Version**: 1.0.0
- **Flutter SDK**: 3.8.1+
- **Dart SDK**: 3.8.1+

## 🤝 Contributing

This is a personal project. For issues or suggestions:
1. Create an issue in the GitHub repository
2. Fork the repository
3. Create a feature branch
4. Submit a pull request

## 📄 License

This project is private and for personal use.

## 🆘 Support

For issues or questions:
- Check the troubleshooting section above
- Review Flutter documentation: https://flutter.dev/docs
- Check package documentation in `pubspec.yaml`

## 🎯 Next Steps

1. **Customize Theme**: Edit `lib/core/theme/app_theme.dart`
2. **Add More Features**: Extend the loan model and screens
3. **Export Data**: Add export functionality (CSV/PDF)
4. **Backup/Restore**: Implement data backup feature

---

**Happy Loan Tracking! 🎉**

