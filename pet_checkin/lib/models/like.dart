/// 点赞记录模型
/// 对应数据库表: likes
/// 与 users 表 N:1，与 checkins 表 N:1 关系 (多对多关系表)
/// 用于记录用户对打卡的点赞，同一用户对同一打卡只能点赞一次 (数据库唯一约束)
class Like {
  /// 点赞 ID (UUID)
  final String id;

  /// 打卡 ID (外键 -> checkins.id)
  final String checkInId;

  /// 点赞用户 ID (外键 -> users.id)
  final String userId;

  /// 点赞时间
  final DateTime createdAt;

  Like({
    required this.id,
    required this.checkInId,
    required this.userId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) => Like(
        id: json['id'] as String,
        checkInId: json['check_in_id'] as String,
        userId: json['user_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'check_in_id': checkInId,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
      };
}