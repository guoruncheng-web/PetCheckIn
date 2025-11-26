/// 用户资料模型
/// 对应数据库表: profiles
/// 与 users 表 1:1 关系，存储用户的详细个人信息
class Profile {
  /// 资料 ID (UUID)
  final String id;

  /// 关联的用户 ID (外键 -> users.id)
  final String userId;

  /// 手机号 (来自 users 表)
  final String phone;

  /// 昵称 (必填)
  final String nickname;

  /// 头像 URL (阿里云 OSS 路径)
  final String? avatarUrl;

  /// 个人简介
  final String? bio;

  /// 性别 ('male' | 'female' | null)
  final String? gender;

  /// 生日
  final DateTime? birthday;

  /// 年龄 (计算字段，非数据库字段)
  final int? age;

  /// 省份
  final String? province;

  /// 城市代码 (对应 cities.dart 中的 code)
  final String? cityCode;

  /// 城市名称
  final String? cityName;

  /// 关注数 (TODO: 待实现关注功能)
  final int followingCount;

  /// 粉丝数 (TODO: 待实现关注功能)
  final int followerCount;

  /// 总获赞数 (所有打卡的点赞数之和)
  final int totalLikes;

  /// 是否已认证 (TODO: 待实现认证功能)
  final bool isVerified;

  /// 最后活跃时间 (TODO: 待实现)
  final DateTime? lastActiveAt;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
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