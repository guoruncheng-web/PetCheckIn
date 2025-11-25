/// 通知
class Notification {
  final String id;
  final String userId;      // 接收者
  final String actorId;     // 触发者
  final String type;        // 见 NotificationType
  final String? checkInId;  // 关联打卡
  final String? content;    // 冗余文案
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.checkInId,
    this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        actorId: json['actor_id'] as String,
        type: json['type'] as String,
        checkInId: json['check_in_id'] as String?,
        content: json['content'] as String?,
        isRead: json['is_read'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'actor_id': actorId,
        'type': type,
        'check_in_id': checkInId,
        'content': content,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  /// 空对象
  factory Notification.empty() => Notification(
        id: '',
        userId: '',
        actorId: '',
        type: NotificationType.like,
        isRead: false,
        createdAt: DateTime.now(),
      );

  /// 复制更新
  Notification copyWith({
    String? id,
    String? userId,
    String? actorId,
    String? type,
    String? checkInId,
    String? content,
    bool? isRead,
    DateTime? createdAt,
  }) =>
      Notification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        actorId: actorId ?? this.actorId,
        type: type ?? this.type,
        checkInId: checkInId ?? this.checkInId,
        content: content ?? this.content,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
}

/// 通知类型常量
abstract class NotificationType {
  static const String like = 'like';
  static const String comment = 'comment';
  static const String follow = 'follow';
  static const String badge = 'badge';
}