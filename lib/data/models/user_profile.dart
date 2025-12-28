import 'package:hive/hive.dart';

/// User profile model for personalization
class UserProfile extends HiveObject {
  String? name;

  UserProfile({
    this.name,
  });

  /// Check if profile has a name
  bool get hasName => name != null && name!.trim().isNotEmpty;

  /// Get display name or fallback
  String get displayName => hasName ? name!.trim() : 'there';

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? name,
  }) {
    return UserProfile(
      name: name ?? this.name,
    );
  }

  /// Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  /// Create from Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String?,
    );
  }
}

