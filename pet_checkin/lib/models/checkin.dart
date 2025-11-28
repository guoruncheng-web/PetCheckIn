/// 打卡记录模型
/// 对应数据库表: checkins
/// 与 users 表 N:1，与 pets 表 N:1 关系
/// 用于记录用户为宠物的每日打卡，支持图片、位置信息
class CheckIn {
  /// 打卡 ID (UUID)
  final String id;

  /// 宠物 ID (外键 -> pets.id)
  final String petId;

  /// 用户 ID (外键 -> users.id)
  final String userId;

  /// 打卡图片 URL 列表 (最多 9 张，阿里云 OSS 路径)
  final List<String> imageUrls;

  /// 城市名称 (来自数据库的 cityName 字段)
  final String? city;

  /// 打卡时间
  final DateTime createdAt;

  // === 冗余字段，方便 UI 展示，非数据库字段 ===

  /// 宠物名称 (从 pet 关联查询)
  final String petName;

  /// 宠物头像 (从 pet 关联查询)
  final String petAvatarUrl;

  /// 点赞数 (实时计算或缓存)
  int likeCount;

  /// 评论数 (实时计算或缓存)
  int commentCount;

  /// 当前用户是否已点赞
  bool isLiked;

  CheckIn({
    required this.id,
    required this.petId,
    required this.userId,
    this.imageUrls = const [],
    this.city,
    required this.createdAt,
    this.petName = '',
    this.petAvatarUrl = '',
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        id: json['id'] as String,
        petId: json['petId'] as String,
        userId: json['userId'] as String,
        imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
        city: json['cityName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        petName: json['pet'] == null ? '' : json['pet']['name'] as String,
        petAvatarUrl: json['pet'] == null ? '' : json['pet']['avatarUrl'] as String,
        likeCount: json['_count'] == null ? 0 : json['_count']['likes'] as int? ?? 0,
        commentCount: json['_count'] == null ? 0 : json['_count']['comments'] as int? ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pet_id': petId,
        'user_id': userId,
        'image_urls': imageUrls,
        'city': city,
        'created_at': createdAt.toIso8601String(),
      };
}

extension CheckInExt on CheckIn {
  String get short {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}