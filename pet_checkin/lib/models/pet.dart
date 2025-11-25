class Pet {
  final String id;
  final String userId;
  final String name;
  final String breed;
  final String gender;
  final DateTime? birthday;
  final int? age;
  final double? weightKg;
  final String? color;
  final String? microchip;
  final bool? neutered;
  final String? description;
  final String? avatarUrl;
  final DateTime createdAt;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.breed,
    required this.gender,
    this.birthday,
    this.age,
    this.weightKg,
    this.color,
    this.microchip,
    this.neutered,
    this.description,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        breed: json['breed'] as String,
        gender: json['gender'] as String,
        birthday: json['birthday'] == null ? null : DateTime.parse(json['birthday'] as String),
        age: json['age'] as int?,
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        color: json['color'] as String?,
        microchip: json['microchip'] as String?,
        neutered: json['neutered'] as bool?,
        description: json['description'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'breed': breed,
        'gender': gender,
        'birthday': birthday?.toIso8601String(),
        'age': age,
        'weight_kg': weightKg,
        'color': color,
        'microchip': microchip,
        'neutered': neutered,
        'description': description,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  static Pet empty() => Pet(
        id: '',
        userId: '',
        name: '',
        breed: '',
        gender: 'MALE',
        createdAt: DateTime.now(),
      );
}