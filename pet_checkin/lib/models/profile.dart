class Profile {
  final String id;
  final String phone;
  final String nickname;
  final String? avatarUrl;
  final String? gender;
  final DateTime? birthday;
  final int? age;
  final String? province;
  final int followingCount;
  final int followerCount;
  final int totalLikes;
  final bool isVerified;
  final DateTime? lastActiveAt;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatarUrl,
    this.gender,
    this.birthday,
    this.age,
    this.province,
    this.followingCount = 0,
    this.followerCount = 0,
    this.totalLikes = 0,
    this.isVerified = false,
    this.lastActiveAt,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        phone: json['phone'] as String,
        nickname: json['nickname'] as String,
        avatarUrl: json['avatar_url'] as String?,
        gender: json['gender'] as String?,
        birthday: json['birthday'] == null ? null : DateTime.parse(json['birthday'] as String),
        age: json['age'] as int?,
        province: json['province'] as String?,
        followingCount: json['following_count'] as int? ?? 0,
        followerCount: json['follower_count'] as int? ?? 0,
        totalLikes: json['total_likes'] as int? ?? 0,
        isVerified: json['is_verified'] as bool? ?? false,
        lastActiveAt: json['last_active_at'] == null ? null : DateTime.parse(json['last_active_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'nickname': nickname,
        'avatar_url': avatarUrl,
        'gender': gender,
        'birthday': birthday?.toIso8601String(),
        'age': age,
        'province': province,
        'following_count': followingCount,
        'follower_count': followerCount,
        'total_likes': totalLikes,
        'is_verified': isVerified,
        'last_active_at': lastActiveAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  static Profile empty() => Profile(
        id: '',
        phone: '',
        nickname: '',
        createdAt: DateTime.now(),
      );
}