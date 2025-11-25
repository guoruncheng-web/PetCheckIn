
class CheckIn {
  final String id;
  final String userId;
  final String petId;
  final String? content;
  final List<String>? images; // JSON 数组
  final DateTime date;
  final DateTime createdAt;

  CheckIn({
    required this.id,
    required this.userId,
    required this.petId,
    this.content,
    this.images,
    required this.date,
    required this.createdAt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        petId: json['pet_id'] as String,
        content: json['content'] as String?,
        images: json['images'] == null ? null : List<String>.from(json['images'] as List),
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'pet_id': petId,
        'content': content,
        'images': images,
        'date': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  /// 空对象
  factory CheckIn.empty() => CheckIn(
        id: '',
        userId: '',
        petId: '',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

  /// 复制更新
  CheckIn copyWith({
    String? id,
    String? userId,
    String? petId,
    String? content,
    List<String>? images,
    DateTime? date,
    DateTime? createdAt,
  }) =>
      CheckIn(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        petId: petId ?? this.petId,
        content: content ?? this.content,
        images: images ?? this.images,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
      );
}