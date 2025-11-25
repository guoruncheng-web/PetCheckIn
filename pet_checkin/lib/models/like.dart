class Like {
  final String id;
  final String checkInId;
  final String userId;
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