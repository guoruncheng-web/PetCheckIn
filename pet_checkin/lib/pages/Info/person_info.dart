import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_checkin/providers/user_provider.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/utils/toast.dart';
import 'package:pet_checkin/services/location_service.dart';
import 'package:pet_checkin/pages/auth/widgets/city_selector.dart';

class MyInfo extends StatefulWidget {
  const MyInfo({super.key});

  @override
  State<MyInfo> createState() => _MyInfoState();
}

class _MyInfoState extends State<MyInfo> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.profile != null) {
        _nicknameController.text = userProvider.profile!.nickname;
        _bioController.text = userProvider.profile!.bio ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
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

      final uploadResult = await ApiService().uploadFile(image.path, 'avatar');

      if (uploadResult['code'] != 200) {
        Toast.error(uploadResult['message'] ?? '上传失败');
        return;
      }

      final avatarUrl = uploadResult['data']['url'];
      if (!mounted) return;

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
      if (!mounted) return;

      final userProvider = context.read<UserProvider>();
      await userProvider.fetchProfile();
      Toast.success('城市已更新为：$cityName');
    } catch (e) {
      Toast.error('更新失败：$e');
    }
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      Toast.error('请输入昵称');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.updateProfile(
        nickname: nickname,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      if (success) {
        Toast.success('保存成功');
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        Toast.error(userProvider.error ?? '保存失败');
      }
    } catch (e) {
      Toast.error('保存失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final profile = userProvider.profile;

        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: CustomScrollView(
            slivers: [
              // 渐变头部区域
              SliverAppBar(
                expandedHeight: 280.h,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF451A03),
                elevation: 0,
                actions: [
                  Container(
                    margin: EdgeInsets.only(right: 8.w),
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : _saveProfile,
                      icon: _isLoading
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF59E0B)),
                              ),
                            )
                          : Icon(Icons.check_circle,
                              size: 18.w, color: const Color(0xFFF59E0B)),
                      label: Text(
                        '保存',
                        style: TextStyle(
                          color: _isLoading
                              ? Colors.grey
                              : const Color(0xFFF59E0B),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF3E0),
                          Color(0xFFFFE0B2),
                          Color(0xFFFFCC80),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 60.h),
                          // 头像
                          GestureDetector(
                            onTap: _pickAndUploadAvatar,
                            child: Hero(
                              tag: 'user_avatar',
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.shade300
                                          .withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: profile.avatarUrl?.isNotEmpty ==
                                                true
                                            ? Image.network(
                                                profile.avatarUrl!,
                                                width: 120.w,
                                                height: 120.w,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 120.w,
                                                height: 120.w,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.orange.shade300,
                                                      Colors.orange.shade500,
                                                    ],
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 60.w,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 4.w,
                                      bottom: 4.w,
                                      child: Container(
                                        width: 36.w,
                                        height: 36.w,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFFFB74D),
                                              Color(0xFFF59E0B),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFF59E0B)
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.camera_alt_rounded,
                                          size: 18.w,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            profile.nickname,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF451A03),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '点击头像更换',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.brown.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 表单内容
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 基本信息卡片
                      _buildSectionCard(
                        title: '基本信息',
                        icon: Icons.person_outline,
                        children: [
                          _buildLabel('昵称', required: true),
                          SizedBox(height: 12.h),
                          TextField(
                            controller: _nicknameController,
                            decoration: _inputDecoration(
                              '请输入昵称',
                              icon: Icons.badge_outlined,
                            ),
                            maxLength: 20,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: const Color(0xFF451A03),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildLabel('个人简介'),
                          SizedBox(height: 12.h),
                          TextField(
                            controller: _bioController,
                            decoration: _inputDecoration(
                              '介绍一下你自己~',
                              icon: Icons.edit_note_rounded,
                            ),
                            maxLines: 4,
                            maxLength: 200,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: const Color(0xFF451A03),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // 位置信息卡片
                      _buildSectionCard(
                        title: '位置信息',
                        icon: Icons.location_on_outlined,
                        children: [
                          InkWell(
                            onTap: _changeCity,
                            borderRadius: BorderRadius.circular(16.r),
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFFFF3E0),
                                    Colors.orange.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.shade100,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.location_city_rounded,
                                      color: const Color(0xFFF59E0B),
                                      size: 24.w,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '所在城市',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.brown.shade600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          profile.cityName ?? '未设置城市',
                                          style: TextStyle(
                                            fontSize: 17.sp,
                                            fontWeight: FontWeight.w600,
                                            color: profile.cityName != null
                                                ? const Color(0xFF451A03)
                                                : Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.orange.shade400,
                                    size: 28.w,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // 账号信息卡片
                      _buildSectionCard(
                        title: '账号信息',
                        icon: Icons.shield_outlined,
                        children: [
                          _buildInfoTile(
                            icon: Icons.phone_android_rounded,
                            label: '手机号',
                            value: profile.phone,
                            iconColor: Colors.blue,
                          ),
                          SizedBox(height: 12.h),
                          _buildInfoTile(
                            icon: Icons.calendar_today_rounded,
                            label: '注册时间',
                            value: _formatDate(profile.createdAt),
                            iconColor: Colors.green,
                          ),
                        ],
                      ),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade50.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFF59E0B),
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF451A03),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF78350F),
          ),
        ),
        if (required)
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '必填',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 15.sp,
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.orange.shade300, size: 22.w)
          : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF451A03),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
