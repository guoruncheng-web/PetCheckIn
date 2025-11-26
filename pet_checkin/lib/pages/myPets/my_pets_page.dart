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
      print('获取宠物列表失败：$e');
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('我的宠物'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF451A03),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPets,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _pets.length,
                    itemBuilder: (context, index) {
                      final pet = _pets[index];
                      return _buildPetCard(pet);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_pet');
          if (result == true && mounted) {
            _loadPets(); // 添加成功后刷新列表
          }
        },
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('添加宠物'),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80.w,
            color: Colors.orange.shade200,
          ),
          SizedBox(height: 16.h),
          Text(
            '还没有宠物',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey),
          ),
          SizedBox(height: 8.h),
          Text(
            '点击下方按钮添加第一只宠物吧',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(context, '/pet_detail', arguments: pet);
        if (result == true && mounted) {
          _loadPets(); // 编辑成功后刷新列表
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
            SizedBox(width: 12.w),
            // 宠物信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pet.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF451A03),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (pet.age != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${pet.age}岁',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  if (pet.breed != null)
                    Text(
                      pet.breed!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      if (pet.gender != null) ...[
                        Icon(
                          pet.gender == 'MALE' ? Icons.male : Icons.female,
                          size: 14.w,
                          color: pet.gender == 'MALE' ? Colors.blueAccent : Colors.pinkAccent,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          pet.gender == 'MALE' ? '弟弟' : '妹妹',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (pet.weightKg != null) ...[
                        if (pet.gender != null) SizedBox(width: 12.w),
                        Icon(Icons.scale, size: 14.w, color: Colors.orangeAccent),
                        SizedBox(width: 4.w),
                        Text(
                          '${pet.weightKg}kg',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 箭头
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }
}
