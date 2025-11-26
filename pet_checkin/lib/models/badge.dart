/// 徽章/成就模型
/// 对应数据库表: badges
/// 与 users 表 N:1 关系
/// 用于记录用户获得的成就徽章（如连续打卡、获赞里程碑等）
class Badge {
  /// 徽章 ID (UUID)
  final String id;

  /// 所属用户 ID (外键 -> users.id)
  final String userId;

  /// 徽章类型 (如: checkin_streak_7, checkin_streak_30, like_master 等)
  /// 同一用户同一类型的徽章唯一 (数据库约束)
  final String type;

  /// 徽章名称 (展示名称)
  final String name;

  /// 徽章描述
  final String description;

  /// 徽章图标 (icon 名称或 URL)
  final String icon;

  /// 徽章等级 (可升级的徽章用此字段，默认为 1)
  final int level;

  /// 获得时间
  final DateTime createdAt;

  Badge({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.level,
    required this.createdAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        level: json['level'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'name': name,
        'description': description,
        'icon': icon,
        'level': level,
        'created_at': createdAt.toIso8601String(),
      };
}