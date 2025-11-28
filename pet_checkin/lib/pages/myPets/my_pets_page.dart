import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/utils/toast.dart';

class MyPetsPage extends StatefulWidget {
  const MyPetsPage({super.key});

  @override
  State<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  List<Pet> _pets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _loading = true);

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
      debugPrint('获取宠物列表失败：$e');
      if (mounted) {
        setState(() {
          _pets = [];
          _loading = false;
        });
        Toast.error('获取宠物列表失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDF6EC),
              Color(0xFFFFFBF7),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 自定义顶部栏
              _buildAppBar(),
              // 内容区域
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF59E0B),
                        ),
                      )
                    : _pets.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: const Color(0xFFF59E0B),
                            onRefresh: _loadPets,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                              itemCount: _pets.length,
                              itemBuilder: (context, index) {
                                final pet = _pets[index];
                                return _buildPetCard(pet);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/add_pet');
            if (result == true && mounted) {
              _loadPets();
            }
          },
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            '添加宠物',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// 自定义顶部栏
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.w,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          // 标题
          Expanded(
            child: Text(
              '我的宠物',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          // 宠物数量
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pets_rounded,
                  size: 16.w,
                  color: const Color(0xFFF59E0B),
                ),
                SizedBox(width: 4.w),
                Text(
                  '${_pets.length}只',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets_rounded,
              size: 64.w,
              color: const Color(0xFFF59E0B),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            '还没有宠物',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '点击下方按钮添加第一只宠物吧',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () async {
        final result =
            await Navigator.pushNamed(context, '/pet_detail', arguments: pet);
        if (result == true && mounted) {
          _loadPets();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
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
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: pet.avatarUrl?.isNotEmpty == true
                    ? Image.network(
                        pet.avatarUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: const Color(0xFFFFF3E0),
                        child: Icon(
                          Icons.pets_rounded,
                          size: 32.w,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
              ),
            ),
            SizedBox(width: 14.w),
            // 宠物信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontSize: 17.sp,
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
                  SizedBox(height: 8.h),
                  // 标签行
                  Row(
                    children: [
                      if (pet.gender != null)
                        _buildTag(
                          icon: pet.gender == 'MALE' ? Icons.male : Icons.female,
                          text: pet.gender == 'MALE' ? '弟弟' : '妹妹',
                          color: pet.gender == 'MALE'
                              ? const Color(0xFF1976D2)
                              : const Color(0xFFE91E63),
                          bgColor: pet.gender == 'MALE'
                              ? const Color(0xFFE3F2FD)
                              : const Color(0xFFFCE4EC),
                        ),
                      if (pet.age != null) ...[
                        SizedBox(width: 8.w),
                        _buildTag(
                          icon: Icons.cake_rounded,
                          text: '${pet.age}岁',
                          color: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFFF3E0),
                        ),
                      ],
                      if (pet.weightKg != null) ...[
                        SizedBox(width: 8.w),
                        _buildTag(
                          icon: Icons.monitor_weight_outlined,
                          text: '${pet.weightKg}kg',
                          color: const Color(0xFF4CAF50),
                          bgColor: const Color(0xFFE8F5E9),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 箭头
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFCCCCCC),
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建标签
  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
