class Badge {
  final String id;
  final String userId;
  final String type;
  final String name;
  final String description;
  final String icon;
  final int level;
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