/// 收藏
class Favorite {
  final String id;
  final String userId;
  final String checkInId;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.checkInId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        checkInId: json['check_in_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'check_in_id': checkInId,
        'created_at': createdAt.toIso8601String(),
      };

  /// 空对象
  factory Favorite.empty() => Favorite(
        id: '',
        userId: '',
        checkInId: '',
        createdAt: DateTime.now(),
      );

  /// 复制更新
  Favorite copyWith({
    String? id,
    String? userId,
    String? checkInId,
    DateTime? createdAt,
  }) =>
      Favorite(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        checkInId: checkInId ?? this.checkInId,
        createdAt: createdAt ?? this.createdAt,
      );
}