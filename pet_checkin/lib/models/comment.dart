class Comment {
  final String id;
  final String checkInId;
  final String userId;
  final String content;
  final DateTime createdAt;

  // 冗余字段
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