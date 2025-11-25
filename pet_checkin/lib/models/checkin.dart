class CheckIn {
  final String id;
  final String petId;
  final String userId;
  final List<String> imageUrls;
  final String? city;
  final DateTime createdAt;

  // 冗余字段，方便 UI 展示
  final String petName;
  final String petAvatarUrl;
  int likeCount;
  int commentCount;
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
        petId: json['pet_id'] as String,
        userId: json['user_id'] as String,
        imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
        city: json['city'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        petName: json['pet'] == null ? '' : json['pet']['name'] as String,
        petAvatarUrl: json['pet'] == null ? '' : json['pet']['avatar_url'] as String,
        likeCount: json['like_count'] as int? ?? 0,
        commentCount: json['comment_count'] as int? ?? 0,
        isLiked: json['is_liked'] as bool? ?? false,
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