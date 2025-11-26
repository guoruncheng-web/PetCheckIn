import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:image_picker/image_picker.dart';
import 'package:pet_checkin/models/profile.dart';
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/models/badge.dart' as pet_badge;
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/providers/user_provider.dart';
import 'package:pet_checkin/utils/toast.dart';
import 'package:pet_checkin/services/location_service.dart';
import 'package:pet_checkin/pages/auth/widgets/city_selector.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Pet> _pets = [];
  List<pet_badge.Badge> _badges = [];

  @override
  void initState() {
    super.initState();
    // 从 UserProvider 获取用户信息，如果为空则刷新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.profile == null && !userProvider.isLoading) {
        userProvider.fetchProfile();
      }
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      Toast.info('正在上传头像...');

      // 1. 上传图片到服务器
      final uploadResult = await ApiService().uploadFile(image.path, 'avatar');

      if (uploadResult['code'] != 200) {
        Toast.error(uploadResult['message'] ?? '上传失败');
        return;
      }

      final avatarUrl = uploadResult['data']['url'];

      // 2. 使用 UserProvider 更新头像
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.updateAvatar(avatarUrl);

      if (success) {
        Toast.success('头像更新成功');
      } else {
        Toast.error(userProvider.error ?? '更新失败');
      }
    } catch (e) {
      Toast.error('头像上传失败：$e');
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      // 清除 Token 和用户信息
      await ApiService().logout();
      final userProvider = context.read<UserProvider>();
      await userProvider.clearProfile();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      Toast.error('退出失败：$e');
    }
  }

  Future<void> _changeCity() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.gps_fixed),
              title: const Text('重新定位'),
              onTap: () => Navigator.pop(context, 'gps'),
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('手动选择'),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    String? cityCode;
    String? cityName;

    if (choice == 'gps') {
      Toast.info('正在定位...');
      try {
        final cityInfo = await LocationService.getCurrentCity();
        if (cityInfo != null) {
          cityCode = cityInfo['cityCode'];
          cityName = cityInfo['cityName'];
        } else {
          Toast.error('定位失败，请重试或手动选择');
          return;
        }
      } catch (e) {
        Toast.error('定位失败：$e');
        return;
      }
    } else {
      final selected = await showCitySelector(context);
      if (selected != null) {
        cityCode = selected.code;
        cityName = selected.name;
      } else {
        return;
      }
    }

    if (cityCode == null || cityName == null) return;

    try {
      Toast.info('正在更新城市...');
      await ApiService().updateCity(cityCode, cityName);

      // 更新本地状态
      final userProvider = context.read<UserProvider>();
      await userProvider.fetchProfile();

      Toast.success('城市已更新为：$cityName');
    } catch (e) {
      Toast.error('更新失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 处理 404 错误：个人信息不存在
        if (userProvider.error == 'PROFILE_NOT_FOUND') {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            Toast.error('个人信息不存在，请重新登录');
            await ApiService().logout();
            await userProvider.clearProfile();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          });
        }

        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final p = userProvider.profile;
        if (p == null) {
          return const Center(child: Text('未找到用户信息'));
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 16.h),
              ),
              _buildHeader(p),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              _buildAchievements(),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              _buildMyPets(),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              _buildMenus(),
              SliverToBoxAdapter(child: SizedBox(height: 32.h)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Profile p) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: Stack(
                children: [
                  ClipOval(
                    child: p.avatarUrl?.isNotEmpty == true
                        ? Image.network(
                            p.avatarUrl!,
                            width: 64.w,
                            height: 64.w,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 64.w,
                            height: 64.w,
                            color: Colors.orange.shade200,
                            child: Icon(
                              Icons.person,
                              size: 32.w,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 12.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.nickname,
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                      ),
                      if (p.isVerified)
                        Padding(
                          padding: EdgeInsets.only(left: 6.w),
                          child: Icon(
                            Icons.verified,
                            size: 16.w,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  GestureDetector(
                    onTap: _changeCity,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14.w,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          p.cityName ?? p.province ?? '未设置城市',
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.edit,
                          size: 12.w,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      _buildCount('关注', p.followingCount),
                      SizedBox(width: 16.w),
                      _buildCount('粉丝', p.followerCount),
                      SizedBox(width: 16.w),
                      _buildCount('获赞', p.totalLikes),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCount(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    if (_badges.isEmpty) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '我的徽章',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 80.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _badges.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (_, i) {
                  final b = _badges[i];
                  return badges.Badge(
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                    ),
                    position: badges.BadgePosition.topEnd(top: -4.h, end: -4.w),
                    badgeContent: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        b.level.toString(),
                        style: TextStyle(fontSize: 10.sp, color: Colors.white),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            _badgeIcon(b.type),
                            size: 24.w,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          b.name,
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _badgeIcon(String type) {
    switch (type) {
      case 'checkin_7':
        return Icons.local_fire_department;
      case 'checkin_30':
        return Icons.star;
      case 'like_100':
        return Icons.favorite;
      case 'comment_50':
        return Icons.comment;
      default:
        return Icons.emoji_events;
    }
  }

  Widget _buildMyPets() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '我的萌宠',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/add_pet'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16.w, color: Colors.orange),
                      SizedBox(width: 4.w),
                      Text(
                        '添加',
                        style: TextStyle(fontSize: 13.sp, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (_pets.isEmpty)
              Center(
                child: Text(
                  '还没有萌宠，点击右上角添加',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                ),
              )
            else
              ..._pets.map((pet) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      ClipOval(
                        child: pet.avatarUrl?.isNotEmpty == true
                            ? Image.network(
                                pet.avatarUrl!,
                                width: 40.w,
                                height: 40.w,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 40.w,
                                height: 40.w,
                                color: Colors.orange.shade200,
                                child: Icon(
                                  Icons.pets,
                                  size: 20.w,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${pet.breed} · ${pet.age}岁',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/pet_detail', arguments: pet),
                        icon: Icon(Icons.chevron_right, size: 20.w, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenus() {
    final menus = [
      {'icon': Icons.bug_report, 'title': '网络日志', 'route': 'network_inspector'},
      {'icon': Icons.settings, 'title': '账号设置', 'route': '/settings'},
      {'icon': Icons.lock, 'title': '隐私政策', 'route': '/privacy'},
      {'icon': Icons.help_outline, 'title': '帮助中心', 'route': '/help'},
      {'icon': Icons.info_outline, 'title': '关于我们', 'route': '/about'},
      {'icon': Icons.logout, 'title': '退出登录', 'route': null},
    ];
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final m = menus[i];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(m['icon'] as IconData, color: Colors.orange),
              title: Text(m['title'] as String, style: TextStyle(fontSize: 14.sp)),
              trailing: Icon(Icons.chevron_right, size: 20.w, color: Colors.grey),
              onTap: () {
                final route = m['route'];
                if (route == null) {
                  _logout();
                } else if (route == 'network_inspector') {
                  // 打开 Alice 网络调试工具
                  ApiService().alice.showInspector();
                } else {
                  Navigator.pushNamed(context, route as String);
                }
              },
            ),
          );
        },
        childCount: menus.length,
      ),
    );
  }
}