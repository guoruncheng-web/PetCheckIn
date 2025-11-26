/// 宠物模型
/// 对应数据库表: pets
/// 与 users 表 N:1 关系，每个用户最多可添加 5 只宠物
class Pet {
  /// 宠物 ID (UUID)
  final String id;

  /// 所属用户 ID (外键 -> users.id)
  final String userId;

  /// 宠物名称 (同一用户下唯一，通过数据库约束保证)
  final String name;

  /// 品种 (如：金毛、泰迪、英短等)
  final String? breed;

  /// 性别 ('MALE' | 'FEMALE')
  final String? gender;

  /// 生日
  final DateTime? birthday;

  /// 体重 (单位: kg)
  final double? weightKg;

  /// 毛色
  final String? color;

  /// 芯片编号 (用于宠物身份识别)
  final String? microchip;

  /// 是否已绝育
  final bool? neutered;

  /// 宠物描述/备注
  final String? description;

  /// 头像 URL (阿里云 OSS 路径)
  final String? avatarUrl;

  /// 照片墙 URLs (最多6张)
  final List<String>? imageUrls;

  /// 视频 URL (1个)
  final String? videoUrl;

  /// 创建时间
  final DateTime createdAt;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    this.breed,
    this.gender,
    this.birthday,
    this.weightKg,
    this.color,
    this.microchip,
    this.neutered,
    this.description,
    this.avatarUrl,
    this.imageUrls,
    this.videoUrl,
    required this.createdAt,
  });

  /// 计算年龄 (根据生日计算)
  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        userId: (json['userId'] ?? json['user_id']) as String,
        name: json['name'] as String,
        breed: json['breed'] as String?,
        gender: json['gender'] as String?,
        birthday: json['birthday'] == null ? null : DateTime.parse(json['birthday'] as String),
        weightKg: ((json['weight'] ?? json['weight_kg']) as num?)?.toDouble(),
        color: json['color'] as String?,
        microchip: json['microchip'] as String?,
        neutered: json['neutered'] as bool?,
        description: json['description'] as String?,
        avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
        imageUrls: (json['imageUrls'] ?? json['image_urls']) != null
            ? List<String>.from((json['imageUrls'] ?? json['image_urls']) as List)
            : null,
        videoUrl: (json['videoUrl'] ?? json['video_url']) as String?,
        createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
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
        'image_urls': imageUrls,
        'video_url': videoUrl,
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