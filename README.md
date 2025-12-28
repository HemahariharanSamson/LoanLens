# LoanLens 📱

A fully offline-first Flutter mobile application for tracking and analyzing multiple loans.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8.1+-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-Private-red)

## 🌟 Features

- ✅ **100% Offline** - No internet required, all data stored locally
- 📊 **Loan Management** - Add, edit, delete multiple loans
- 📈 **Analytics Dashboard** - Visual charts and trends
- 💰 **Past Payments Support** - Track existing loans with payment history
- 🚪 **Early Closure** - Close loans early with settlement tracking
- 🔔 **Smart Notifications** - Monthly EMI reminders
- 🎨 **Minimalist UI** - Clean, modern, finance-grade design
- 🌓 **Theme Support** - Light mode (dark mode compatible)

## 📸 Screenshots

*Add screenshots of your app here*

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio or VS Code
- Android SDK
- JDK 11+

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd LoanTracker

# Install dependencies
flutter pub get

# Run the app
flutter run
```

For detailed setup instructions, see [SETUP.md](SETUP.md).

## 📖 Documentation

- [Setup Guide](SETUP.md) - Complete installation and usage instructions
- [Project Structure](SETUP.md#-project-structure) - Code organization
- [Troubleshooting](SETUP.md#-troubleshooting) - Common issues and solutions

## 🏗️ Architecture

- **State Management**: Riverpod
- **Local Storage**: Hive
- **Charts**: fl_chart
- **Notifications**: flutter_local_notifications
- **Architecture**: Clean Architecture with feature-based structure

## 📦 Dependencies

Key packages:
- `flutter_riverpod` - State management
- `hive` & `hive_flutter` - Offline storage
- `fl_chart` - Charts and visualizations
- `flutter_local_notifications` - Local notifications
- `intl` - Internationalization
- `uuid` - Unique ID generation

See `pubspec.yaml` for complete list.

## 🎯 Use Cases

- Track multiple loans (home, car, personal, etc.)
- Monitor repayment progress
- Analyze loan distribution
- Plan early closure
- Get EMI reminders

## 🔒 Privacy

- **100% Offline** - No data leaves your device
- **No Backend** - No cloud storage
- **No Login** - No authentication required
- **Local Only** - All data stored on device

## 📱 Platform Support

- ✅ Android (Primary)
- ✅ iOS (Compatible)

## 🛠️ Development

### Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/          # Constants, theme, utils, services
├── data/          # Models, repositories, storage
├── features/       # Dashboard, loans, analytics
├── widgets/       # Reusable components
└── routes/        # Navigation
```

### Building

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

## 📝 Version History

### v1.0.0 (Current)
- Initial release
- Loan management (CRUD)
- Past payments support
- Early closure functionality
- Analytics dashboard
- Local notifications
- Charts and visualizations

## 🤝 Contributing

This is a personal project. For issues or suggestions, please open an issue.

## 📄 License

Private - Personal use only

## 👤 Author

Your Name

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Package maintainers for excellent libraries
- Open source community

---

**Made with ❤️ using Flutter**
