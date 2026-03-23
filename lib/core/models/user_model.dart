class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final DateTime createdAt;
  final bool isPremium;
  final String? fcmToken;

  UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    required this.createdAt,
    required this.isPremium,
    this.fcmToken,
  });

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    DateTime? createdAt,
    bool? isPremium,
    String? fcmToken,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPremium: json['isPremium'] as bool? ?? false,
      fcmToken: json['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'isPremium': isPremium,
      'fcmToken': fcmToken,
    };
  }
}

class QuizStats {
  final String category;
  final int totalAttempts;
  final int totalCorrect;
  final DateTime? lastAttemptAt;

  QuizStats({
    required this.category,
    required this.totalAttempts,
    required this.totalCorrect,
    this.lastAttemptAt,
  });

  double get percentageCorrect {
    if (totalAttempts == 0) return 0;
    return (totalCorrect / totalAttempts) * 100;
  }

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    return QuizStats(
      category: json['category'] as String,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'totalAttempts': totalAttempts,
      'totalCorrect': totalCorrect,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    };
  }
}
