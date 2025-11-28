import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/models/checkin.dart';
import 'package:pet_checkin/providers/user_provider.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/ui/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Pet> _pets = [];
  List<CheckIn> _todayCheckIns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 获取用户个人信息
    final userProvider = context.read<UserProvider>();
    if (userProvider.profile == null && !userProvider.isLoading) {
      await userProvider.fetchProfile();
    }

    // 获取宠物列表
    try {
      final result = await ApiService().getMyPets();

      if (mounted && result['code'] == 200) {
        final List<dynamic> petsData = result['data'] ?? [];
        setState(() {
          _pets = petsData.map((json) => Pet.fromJson(json)).toList();
        });
      } else {
        if (mounted) {
          setState(() {
            _pets = [];
          });
        }
      }
    } catch (e) {
      debugPrint('获取宠物列表失败：$e');
      if (mounted) {
        setState(() {
          _pets = [];
        });
      }
    }

    // 获取今日打卡列表
    try {
      final result = await ApiService().getMyCheckIns(page: 1, limit: 20);

      if (mounted && result['code'] == 200) {
        final List<dynamic> checkInsData = result['data'] ?? [];
        final allCheckIns =
            checkInsData.map((json) => CheckIn.fromJson(json)).toList();

        // 过滤出今天的打卡记录
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

        setState(() {
          _todayCheckIns = allCheckIns.where((ci) {
            return ci.createdAt.isAfter(today) &&
                ci.createdAt.isBefore(tomorrow);
          }).toList();
          _loading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _todayCheckIns = [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('获取今日打卡失败：$e');
      if (mounted) {
        setState(() {
          _todayCheckIns = [];
          _loading = false;
        });
      }
    }
  }

  /// 请求地理位置权限并获取位置
  Future<void> _requestLocationAndCheckIn() async {
    // 检查定位服务是否开启
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationDialog(
          '定位服务未开启',
          '请在系统设置中开启定位服务后再试',
        );
      }
      return;
    }

    // 检查定位权限
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // 请求权限
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showLocationDialog(
            '需要定位权限',
            '打卡功能需要获取您的位置信息,用于显示同城动态',
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 权限被永久拒绝,引导用户去设置
      if (mounted) {
        _showLocationDialog(
          '定位权限被拒绝',
          '请在系统设置中允许定位权限后再试',
          showSettings: true,
        );
      }
      return;
    }

    // 权限已授予,获取位置
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        // 跳转到打卡页面,传递位置信息
        final result = await Navigator.pushNamed(
          context,
          '/checkin',
          arguments: position,
        );

        // 如果打卡成功,刷新首页数据
        if (result == true && mounted) {
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        _showLocationDialog(
          '获取位置失败',
          '请检查定位服务是否正常: $e',
        );
      }
    }
  }

  /// 显示位置权限对话框
  void _showLocationDialog(String title, String message,
      {bool showSettings = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          if (showSettings)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings(); // 打开系统设置
              },
              child: const Text('去设置'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _requestLocationAndCheckIn(); // 重试
              },
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFDF6EC),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDF6EC), // 顶部暖黄色
              Color(0xFFFFFBF7), // 底部白色
            ],
            stops: [0.0, 0.35],
          ),
        ),
        child: RefreshIndicator(
          color: const Color(0xFFF59E0B),
          onRefresh: _loadData,
          child: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return CustomScrollView(
                slivers: [
                  // 顶部安全区域
                  SliverToBoxAdapter(
                    child: SizedBox(height: MediaQuery.of(context).padding.top),
                  ),
                  // 用户欢迎区域
                  _buildHeader(userProvider),
                  // 宠物区域
                  if (_pets.isNotEmpty) _buildPetSection(),
                  if (_pets.isEmpty) _buildEmptyPets(),
                  // 今日打卡
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                  _buildTodayCheckIn(),
                  SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _pets.isEmpty
          ? Padding(
              padding: EdgeInsets.only(bottom: 80.h),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/add_pet');
                  if (result == true && mounted) {
                    _loadData();
                  }
                },
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            )
          : null,
    );
  }

  /// 顶部头像和打卡按钮 - 浮动卡片样式
  Widget _buildHeader(UserProvider userProvider) {
    final profile = userProvider.profile;
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 头像
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: profile?.avatarUrl?.isNotEmpty == true
                      ? Image.network(
                          profile!.avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: const Color(0xFFFFF3E0),
                          child: Icon(
                            Icons.person_rounded,
                            size: 26.w,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // 欢迎语
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '你好，${profile?.nickname ?? "宠友"}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            // 打卡按钮
            GestureDetector(
              onTap: _requestLocationAndCheckIn,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pets_rounded, size: 18.w, color: Colors.white),
                    SizedBox(width: 6.w),
                    Text(
                      '打卡',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '早上好，今天也要元气满满哦~';
    if (hour < 18) return '下午好，记得给宠物打卡哦~';
    return '晚上好，和宠物度过美好时光~';
  }

  /// 宠物区域
  Widget _buildPetSection() {
    final displayPets = _pets.take(2).toList();
    final hasMore = _pets.length > 2;

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.pets_rounded,
                    size: 18.w,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '我的宠物',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                if (hasMore)
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.pushNamed(context, '/my_pets');
                      if (result == true && mounted) _loadData();
                    },
                    child: Row(
                      children: [
                        Text(
                          '全部 ${_pets.length}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF999999),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18.w,
                          color: const Color(0xFF999999),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            // 宠物列表
            ...displayPets.map((pet) => _buildPetItem(pet)),
          ],
        ),
      ),
    );
  }

  /// 单个宠物项
  Widget _buildPetItem(Pet pet) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(context, '/pet_detail', arguments: pet);
        if (result == true && mounted) _loadData();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF7),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 头像
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: pet.avatarUrl?.isNotEmpty == true
                    ? Image.network(pet.avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFFFF3E0),
                        child: Icon(
                          Icons.pets_rounded,
                          size: 28.w,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
              ),
            ),
            SizedBox(width: 14.w),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    pet.breed ?? '未知品种',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            // 性别年龄标签
            if (pet.gender != null || pet.age != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: pet.gender == 'MALE'
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pet.gender != null)
                      Icon(
                        pet.gender == 'MALE' ? Icons.male : Icons.female,
                        size: 14.w,
                        color: pet.gender == 'MALE'
                            ? const Color(0xFF1976D2)
                            : const Color(0xFFE91E63),
                      ),
                    if (pet.age != null) ...[
                      if (pet.gender != null) SizedBox(width: 4.w),
                      Text(
                        '${pet.age}岁',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: pet.gender == 'MALE'
                              ? const Color(0xFF1976D2)
                              : const Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.w,
              color: const Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }

  // 保留旧方法名以兼容
  Widget _buildPetCards() => _buildPetSection();

  Widget _buildEmptyPets() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(vertical: 48.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets_rounded,
                size: 48.w,
                color: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              '还没有添加宠物',
              style: TextStyle(
                fontSize: 17.sp,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '点击右下角按钮添加你的第一只宠物吧',
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCheckIn() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18.w,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '今日打卡',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${_todayCheckIns.length}次',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (_todayCheckIns.isEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 48.w,
                        color: const Color(0xFFE0E0E0),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '今天还没有打卡记录',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._todayCheckIns.map((ci) {
                final pet = _pets.firstWhere(
                  (p) => p.id == ci.petId,
                  orElse: () => Pet.empty(),
                );
                return _buildCheckInItem(ci, pet);
              }),
          ],
        ),
      ),
    );
  }

  /// 打卡记录项
  Widget _buildCheckInItem(CheckIn ci, Pet pet) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: pet.avatarUrl?.isNotEmpty == true
                  ? Image.network(pet.avatarUrl!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFFFF3E0),
                      child: Icon(
                        Icons.pets_rounded,
                        size: 22.w,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  ci.createdAt.hourMinute,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          // 完成标记
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 16.w,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

}

extension _TimeExt on DateTime {
  String get hourMinute =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
