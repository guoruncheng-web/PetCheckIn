import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:badges/badges.dart' as badges;
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/models/checkin.dart';
import 'package:pet_checkin/services/supabase_service.dart';
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
  int _currentPetIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId == null) return;
      final pets = await SupabaseService.instance.listMyPets(userId);
      final checkins = await SupabaseService.instance.listTodayCheckIns(userId);
      if (mounted) {
        setState(() {
          _pets = pets;
          _todayCheckIns = checkins;
          _loading = false;
        });
      }
    } catch (e) {
      Toast.error('加载失败：$e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIn() async {
    if (_pets.isEmpty) {
      Toast.info('请先添加宠物');
      return;
    }
    final pet = _pets[_currentPetIndex];
    try {
      await SupabaseService.instance.createCheckIn(pet.id);
      Toast.success('打卡成功');
      await _loadData();
    } catch (e) {
      Toast.error('打卡失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          if (_pets.isNotEmpty) _buildPetCards(),
          if (_pets.isEmpty) _buildEmptyPets(),
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
          _buildTodayCheckIn(),
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }

  Widget _buildPetCards() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180.h,
        child: PageView.builder(
          itemCount: _pets.length,
          onPageChanged: (i) => setState(() => _currentPetIndex = i),
          padEnds: false,
          controller: PageController(viewportFraction: 0.78, initialPage: 0),
          itemBuilder: (ctx, i) {
            final pet = _pets[i];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/pet_detail', arguments: pet),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8.w),
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
                        badgeContent: Text(
                          '${pet.age}岁',
                          style: TextStyle(fontSize: 10.sp, color: Colors.orange),
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
                      padding: EdgeInsets.only(left: 20.w, bottom: 20.h, top: 24.h),
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
                          Text(
                            pet.breed,
                            style: TextStyle(fontSize: 12.sp, color: Colors.brown.shade600),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Icon(Icons.female, size: 14.w, color: Colors.pinkAccent),
                              SizedBox(width: 4.w),
                              Text(
                                pet.gender == 'MALE' ? '弟弟' : '妹妹',
                                style: TextStyle(fontSize: 12.sp, color: Colors.brown.shade700),
                              ),
                              SizedBox(width: 12.w),
                              Icon(Icons.scale, size: 14.w, color: Colors.blueAccent),
                              SizedBox(width: 4.w),
                              Text(
                                '${pet.weightKg}kg',
                                style: TextStyle(fontSize: 12.sp, color: Colors.brown.shade700),
                              ),
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
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            ci.createdAt.hourMinute,
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
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
  String get hourMinute => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}