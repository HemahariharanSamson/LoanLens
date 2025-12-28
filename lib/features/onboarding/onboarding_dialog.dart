import 'package:flutter/material.dart';
import '../../data/models/user_profile.dart';
import '../../data/local/sqlite_storage.dart';

/// Onboarding dialog to collect user's name on first launch or update existing name
class OnboardingDialog extends StatefulWidget {
  final String? initialName;
  final bool isUpdate;

  const OnboardingDialog({
    super.key,
    this.initialName,
    this.isUpdate = false,
  });

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final profile = UserProfile(name: name.isEmpty ? null : name);
      
      try {
        final storage = SqliteStorage();
        await storage.saveUserProfile(profile);
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving name: $e')),
          );
        }
      }
    }
  }

  void _skip() {
    // Save empty profile to mark onboarding as completed
    final profile = UserProfile(name: null);
    SqliteStorage().saveUserProfile(profile).then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }).catchError((e) {
      // Even if save fails, close dialog to not block user
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                widget.isUpdate ? 'Update Profile' : 'Welcome to LoanLens',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                widget.isUpdate 
                    ? 'Update your name' 
                    : 'What should we call you?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Name input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your name (optional)',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
                validator: (value) {
                  // No validation needed - optional field
                  return null;
                },
                onFieldSubmitted: (_) => _saveName(),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  if (!widget.isUpdate)
                    Expanded(
                      child: TextButton(
                        onPressed: _skip,
                        child: const Text('Skip'),
                      ),
                    ),
                  if (!widget.isUpdate) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveName,
                      child: Text(widget.isUpdate ? 'Save' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

