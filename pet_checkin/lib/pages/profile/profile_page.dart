import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:badges/badges.dart' as badges;
import 'package:pet_checkin/models/profile.dart';
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/models/badge.dart' as pet_badge;
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/utils/toast.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  List<Pet> _pets = [];
  List<pet_badge.Badge> _badges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ApiService().getMyProfile();
      if (!mounted) return;

      if (result['code'] == 200 && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _profile = Profile(
            id: data['id'],
            userId: data['userId'],
            nickname: data['nickname'],
            avatarUrl: data['avatarUrl'],
            bio: data['bio'],
            phone: data['phone'],
            cityCode: data['cityCode'],
            cityName: data['cityName'],
            province: data['province'],
            isVerified: data['isVerified'] ?? false,
            followingCount: data['followingCount'] ?? 0,
            followerCount: data['followerCount'] ?? 0,
            totalLikes: data['totalLikes'] ?? 0,
            createdAt: DateTime.parse(data['createdAt']),
            updatedAt: DateTime.parse(data['updatedAt']),
          );
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        Toast.error(result['message'] ?? '加载个人信息失败');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        // Token 无效或服务器错误，清除 Token 并跳转到登录页
        await ApiService().clearToken();
        Toast.error('登录已失效，请重新登录');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
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
      // TODO: 迁移到 NestJS API - 调用 ApiService().logout()
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      Toast.error('退出失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final p = _profile;
    if (p == null) {
      return const Center(child: Text('未找到用户信息'));
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
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
                  Text(
                    p.province ?? '未知城市',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey),
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