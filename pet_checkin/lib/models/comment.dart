/// 评论模型
/// 对应数据库表: comments
/// 与 users 表 N:1，与 checkins 表 N:1 关系
/// 支持嵌套回复 (通过 parentId 实现，数据库中有 parent/replies 自关联)
class Comment {
  /// 评论 ID (UUID)
  final String id;

  /// 打卡 ID (外键 -> checkins.id)
  final String checkInId;

  /// 评论用户 ID (外键 -> users.id)
  final String userId;

  /// 评论内容
  final String content;

  /// 创建时间
  final DateTime createdAt;

  // === 冗余字段，方便 UI 展示，非数据库字段 ===

  /// 评论用户昵称 (从 user 关联查询)
  final String userNickname;

  Comment({
    required this.id,
    required this.checkInId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userNickname = '',
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        checkInId: json['check_in_id'] as String,
        userId: json['user_id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        userNickname: json['user'] == null ? '' : json['user']['nickname'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'check_in_id': checkInId,
        'user_id': userId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}