class Profile {
  final String id;
  final String userId;
  final String phone;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final DateTime? birthday;
  final int? age;
  final String? province;
  final String? cityCode;
  final String? cityName;
  final int followingCount;
  final int followerCount;
  final int totalLikes;
  final bool isVerified;
  final DateTime? lastActiveAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    required this.userId,
    required this.phone,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.birthday,
    this.age,
    this.province,
    this.cityCode,
    this.cityName,
    this.followingCount = 0,
    this.followerCount = 0,
    this.totalLikes = 0,
    this.isVerified = false,
    this.lastActiveAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        userId: json['userId'] as String,
        phone: json['phone'] as String,
        nickname: json['nickname'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        gender: json['gender'] as String?,
        birthday: json['birthday'] == null ? null : DateTime.parse(json['birthday'] as String),
        age: json['age'] as int?,
        province: json['province'] as String?,
        cityCode: json['cityCode'] as String?,
        cityName: json['cityName'] as String?,
        followingCount: json['followingCount'] as int? ?? 0,
        followerCount: json['followerCount'] as int? ?? 0,
        totalLikes: json['totalLikes'] as int? ?? 0,
        isVerified: json['isVerified'] as bool? ?? false,
        lastActiveAt: json['lastActiveAt'] == null ? null : DateTime.parse(json['lastActiveAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'phone': phone,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'gender': gender,
        'birthday': birthday?.toIso8601String(),
        'age': age,
        'province': province,
        'cityCode': cityCode,
        'cityName': cityName,
        'followingCount': followingCount,
        'followerCount': followerCount,
        'totalLikes': totalLikes,
        'isVerified': isVerified,
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static Profile empty() => Profile(
        id: '',
        userId: '',
        phone: '',
        nickname: '',
        createdAt: DateTime.now(),
      );
}