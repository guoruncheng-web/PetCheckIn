import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/models/checkin.dart';
import 'package:pet_checkin/providers/user_provider.dart';
import 'package:pet_checkin/services/api_service.dart';
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
      print('获取宠物列表失败：$e');
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
        final allCheckIns = checkInsData.map((json) => CheckIn.fromJson(json)).toList();

        // 过滤出今天的打卡记录
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

        setState(() {
          _todayCheckIns = allCheckIns.where((ci) {
            return ci.createdAt.isAfter(today) && ci.createdAt.isBefore(tomorrow);
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
      print('获取今日打卡失败：$e');
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
        desiredAccuracy: LocationAccuracy.high,
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
  void _showLocationDialog(String title, String message, {bool showSettings = false}) {
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
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 16.h)),
                // 用户欢迎区域
                _buildWelcomeSection(userProvider),
                if (_pets.isNotEmpty) _buildPetCards(),
                if (_pets.isEmpty) _buildEmptyPets(),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                _buildTodayCheckIn(),
                SliverToBoxAdapter(child: SizedBox(height: 32.h)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _pets.isEmpty
          ? Padding(
              padding: EdgeInsets.only(bottom: 80.h), // 避免被网络调试按钮遮挡
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/add_pet');
                  if (result == true && mounted) {
                    // 添加成功后刷新列表
                    _loadData();
                  }
                },
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.add, size: 32),
              ),
            )
          : null,
    );
  }

  /// 构建欢迎区域，显示用户信息
  Widget _buildWelcomeSection(UserProvider userProvider) {
    final profile = userProvider.profile;

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 头像
            ClipOval(
              child: profile?.avatarUrl?.isNotEmpty == true
                  ? Image.network(
                      profile!.avatarUrl!,
                      width: 50.w,
                      height: 50.w,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 50.w,
                      height: 50.w,
                      color: Colors.orange.shade300,
                      child: Icon(
                        Icons.person,
                        size: 28.w,
                        color: Colors.white,
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '你好，${profile?.nickname ?? "宠友"}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF451A03),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.waving_hand,
                        size: 18.w,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  if (profile?.cityName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12.w,
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          profile!.cityName!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.brown.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // 打卡按钮
            GestureDetector(
              onTap: _requestLocationAndCheckIn,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16.w,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '打卡',
                      style: TextStyle(
                        fontSize: 13.sp,
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

  Widget _buildPetCards() {
    // 最多展示2只宠物
    final displayPets = _pets.take(2).toList();
    final hasMore = _pets.length > 2;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
        child: Transform.translate(
          offset: Offset(0, -16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid布局展示宠物
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 0.85,
                ),
                itemCount: displayPets.length,
                itemBuilder: (ctx, i) {
                  final pet = displayPets[i];
                  return _buildPetCard(pet);
                },
              ),
              // 如果有更多宠物，显示"更多"按钮
              if (hasMore) ...[
                SizedBox(height: 12.h),
                InkWell(
                  onTap: () async {
                    final result = await Navigator.pushNamed(context, '/my_pets');
                    if (result == true && mounted) {
                      _loadData(); // 刷新数据
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '查看全部 ${_pets.length} 只宠物',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.chevron_right,
                          size: 18.w,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建单个宠物卡片
  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () async {
        final result =
            await Navigator.pushNamed(context, '/pet_detail', arguments: pet);
        if (result == true && mounted) {
          _loadData(); // 编辑成功后刷新数据
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16.h),
            // 头像
            ClipOval(
              child: pet.avatarUrl?.isNotEmpty == true
                  ? Image.network(
                      pet.avatarUrl!,
                      width: 60.w,
                      height: 60.w,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60.w,
                      height: 60.w,
                      color: Colors.orange.shade200,
                      child: Icon(
                        Icons.pets,
                        size: 30.w,
                        color: Colors.white,
                      ),
                    ),
            ),
            SizedBox(height: 12.h),
            // 名字
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                pet.name,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 4.h),
            // 品种
            if (pet.breed != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  pet.breed!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.brown.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(),
            // 底部信息
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (pet.gender != null) ...[
                    Icon(
                      pet.gender == 'MALE' ? Icons.male : Icons.female,
                      size: 14.w,
                      color: pet.gender == 'MALE'
                          ? Colors.blueAccent
                          : Colors.pinkAccent,
                    ),
                    SizedBox(width: 2.w),
                  ],
                  if (pet.age != null)
                    Text(
                      '${pet.age}岁',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.brown.shade700,
                      ),
                    ),
                  if (pet.weightKg != null) ...[
                    SizedBox(width: 8.w),
                    Icon(Icons.scale, size: 14.w, color: Colors.orangeAccent),
                    SizedBox(width: 2.w),
                    Text(
                      '${pet.weightKg}kg',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.brown.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPets() {
    return SliverToBoxAdapter(
      child: Center(
        child: Column(
          children: [
            SizedBox(height: 40.h),
            Icon(
              Icons.pets,
              size: 80.w,
              color: Colors.orange.shade200,
            ),
            SizedBox(height: 16.h),
            Text(
              '还没有萌宠',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
            SizedBox(height: 8.h),
            Text(
              '点击下方“+”添加第一只宠物吧',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCheckIn() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              '今日打卡',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 12.h),
          if (_todayCheckIns.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text(
                    '今天还没有打卡记录',
                    style: TextStyle(fontSize: 14.sp, color: Colors.orange),
                  ),
                ),
              ),
            )
          else
            ..._todayCheckIns.map((ci) {
              final pet = _pets.firstWhere((p) => p.id == ci.petId,
                  orElse: () => Pet.empty());
              return Container(
                margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 12.h),
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
                            style: TextStyle(
                                fontSize: 15.sp, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            ci.createdAt.hourMinute,
                            style:
                                TextStyle(fontSize: 12.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, size: 20.w, color: Colors.green),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

extension _TimeExt on DateTime {
  String get hourMinute =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
