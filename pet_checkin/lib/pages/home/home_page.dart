import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/models/checkin.dart';
import 'package:pet_checkin/providers/user_provider.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/utils/toast.dart';

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
          _loading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _pets = [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      print('获取宠物列表失败：$e');
      if (mounted) {
        setState(() {
          _pets = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _checkIn() async {
    Toast.info('功能开发中...');
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
                SliverToBoxAdapter(child: SizedBox(height: 20.h)),
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPetCards() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180.h,
        child: PageView.builder(
          itemCount: _pets.length,
          onPageChanged: (i) => setState(() {}),
          padEnds: false,
          controller: PageController(viewportFraction: 1.0, initialPage: 0),
          itemBuilder: (ctx, i) {
            final pet = _pets[i];
            return GestureDetector(
              onTap: () async {
                final result = await Navigator.pushNamed(context, '/pet_detail',
                    arguments: pet);
                if (result == true && mounted) {
                  _loadData(); // 编辑成功后刷新数据
                }
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade100,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 12.w,
                      top: 12.h,
                      child: badges.Badge(
                        badgeStyle: badges.BadgeStyle(
                          badgeColor: Colors.white,
                          padding: EdgeInsets.all(4.w),
                        ),
                        child: ClipOval(
                          child: pet.avatarUrl?.isNotEmpty == true
                              ? Image.network(
                                  pet.avatarUrl!,
                                  width: 64.w,
                                  height: 64.w,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 64.w,
                                  height: 64.w,
                                  color: Colors.orange.shade200,
                                  child: Icon(
                                    Icons.pets,
                                    size: 32.w,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.only(left: 20.w, bottom: 20.h, top: 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            pet.name,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade800,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          if (pet.breed != null)
                            Text(
                              pet.breed!,
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.brown.shade600),
                            ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              if (pet.gender != null) ...[
                                Icon(
                                    pet.gender == 'MALE'
                                        ? Icons.male
                                        : Icons.female,
                                    size: 14.w,
                                    color: pet.gender == 'MALE'
                                        ? Colors.blueAccent
                                        : Colors.pinkAccent),
                                SizedBox(width: 4.w),
                                Text(
                                  pet.gender == 'MALE' ? '弟弟' : '妹妹',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.brown.shade700),
                                ),
                              ],
                              if (pet.weightKg != null) ...[
                                if (pet.gender != null) SizedBox(width: 12.w),
                                Icon(Icons.scale,
                                    size: 14.w, color: Colors.orangeAccent),
                                SizedBox(width: 4.w),
                                Text(
                                  '${pet.weightKg}kg',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.brown.shade700),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 16.w,
                      bottom: 16.h,
                      child: ElevatedButton(
                        onPressed: _checkIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16.w),
                            SizedBox(width: 4.w),
                            Text('打卡', style: TextStyle(fontSize: 12.sp)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
