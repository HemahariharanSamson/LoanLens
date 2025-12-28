import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/sqlite_storage.dart';
import 'onboarding_dialog.dart';

/// Wrapper widget that shows onboarding dialog on first launch
class OnboardingWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const OnboardingWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  bool _hasCheckedOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Check onboarding status after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOnboarding();
    });
  }

  Future<void> _checkAndShowOnboarding() async {
    if (_hasCheckedOnboarding || !mounted) return;
    _hasCheckedOnboarding = true;

    try {
      final storage = SqliteStorage();
      final profile = await storage.getUserProfile();
      
      // Show dialog if onboarding not completed OR if no name is set
      if ((profile == null || !profile.hasName) && mounted) {
        // Show onboarding dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const OnboardingDialog(),
        );
      }
    } catch (e) {
      // If check fails, don't block the app
      debugPrint('Error checking onboarding status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

