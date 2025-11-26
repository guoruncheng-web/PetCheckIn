import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/utils/toast.dart';

/// 添加宠物页面
class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _avatarUrl;
  String _gender = 'MALE';
  DateTime? _birthday;
  bool _isSubmitting = false;

  // 多张照片和视频
  final List<String> _imageUrls = []; // 最多6张照片
  String? _videoUrl; // 1个视频

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 选择并上传宠物头像
  Future<void> _pickAvatar() async {
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

      // 上传到服务器
      final uploadResult = await ApiService().uploadFile(image.path, 'pet_avatar');

      if (uploadResult['code'] != 200) {
        Toast.error(uploadResult['message'] ?? '上传失败');
        return;
      }

      setState(() {
        _avatarUrl = uploadResult['data']['url'];
      });

      Toast.success('头像上传成功');
    } catch (e) {
      Toast.error('头像上传失败：$e');
    }
  }

  /// 选择并上传多张照片（最多6张）
  Future<void> _pickImages() async {
    if (_imageUrls.length >= 6) {
      Toast.info('最多只能上传6张照片');
      return;
    }

    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      // 检查总数量
      final remainingSlots = 6 - _imageUrls.length;
      final imagesToUpload = images.take(remainingSlots).toList();

      if (images.length > remainingSlots) {
        Toast.info('只能再上传$remainingSlots张照片');
      }

      Toast.info('正在上传照片...');

      // 逐个上传
      for (final image in imagesToUpload) {
        final uploadResult = await ApiService().uploadFile(image.path, 'pet_photo');

        if (uploadResult['code'] != 200) {
          Toast.error('照片上传失败：${uploadResult['message']}');
          continue;
        }

        setState(() {
          _imageUrls.add(uploadResult['data']['url']);
        });
      }

      Toast.success('照片上传成功');
    } catch (e) {
      Toast.error('照片上传失败：$e');
    }
  }

  /// 删除照片
  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  /// 选择并上传视频
  Future<void> _pickVideo() async {
    if (_videoUrl != null) {
      Toast.info('只能上传1个视频');
      return;
    }

    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );

      if (video == null) return;

      Toast.info('正在上传视频...');

      // 上传到服务器
      final uploadResult = await ApiService().uploadFile(video.path, 'pet_video');

      if (uploadResult['code'] != 200) {
        Toast.error(uploadResult['message'] ?? '上传失败');
        return;
      }

      setState(() {
        _videoUrl = uploadResult['data']['url'];
      });

      Toast.success('视频上传成功');
    } catch (e) {
      Toast.error('视频上传失败：$e');
    }
  }

  /// 删除视频
  void _removeVideo() {
    setState(() {
      _videoUrl = null;
    });
  }

  /// 选择生日
  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 1),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      helpText: '选择生日',
      cancelText: '取消',
      confirmText: '确定',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF59E0B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF451A03),
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _birthday = picked);
    }
  }

  /// 提交表单
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await ApiService().createPet(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        gender: _gender,
        avatarUrl: _avatarUrl,
        birthday: _birthday,
        weight: _weightController.text.isEmpty
            ? null
            : double.tryParse(_weightController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrls: _imageUrls.isNotEmpty ? _imageUrls : null,
        videoUrl: _videoUrl,
      );

      if (!mounted) return;

      if (result['code'] == 200 || result['code'] == 201) {
        Toast.success('宠物添加成功');
        Navigator.pop(context, true); // 返回 true 表示添加成功
      } else {
        Toast.error(result['message'] ?? '添加失败');
      }
    } catch (e) {
      Toast.error('添加失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('添加宠物'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF451A03),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h), // 增加底部padding避免按钮被遮挡
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 头像
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                        width: 3,
                      ),
                    ),
                    child: _avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _avatarUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.pets,
                            size: 50.w,
                            color: const Color(0xFFF59E0B),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('上传头像'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // 宠物名称
              _buildLabel('宠物名称', required: true),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('请输入宠物名称'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入宠物名称';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              // 品种
              _buildLabel('品种', required: true),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _breedController,
                decoration: _inputDecoration('如：金毛、泰迪、英短等'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入宠物品种';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              // 性别
              _buildLabel('性别'),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderButton('男生', 'MALE'),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildGenderButton('女生', 'FEMALE'),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // 生日
              _buildLabel('生日'),
              SizedBox(height: 8.h),
              InkWell(
                onTap: _selectBirthday,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFEF3C7)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cake_outlined, color: const Color(0xFFF59E0B), size: 20.w),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _birthday != null
                              ? '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'
                              : '请选择生日',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: _birthday != null ? const Color(0xFF451A03) : Colors.grey[400],
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 20.w),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // 体重
              _buildLabel('体重 (kg)'),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _weightController,
                decoration: _inputDecoration('如：5.5'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 20.h),

              // 简介
              _buildLabel('宠物简介'),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('介绍一下你的宠物吧~'),
                maxLines: 4,
                maxLength: 200,
              ),
              SizedBox(height: 20.h),

              // 照片墙（最多6张）
              _buildLabel('照片（最多6张）'),
              SizedBox(height: 8.h),
              _buildPhotoGrid(),
              SizedBox(height: 20.h),

              // 视频（最多1个）
              _buildLabel('视频（最多1个）'),
              SizedBox(height: 8.h),
              _buildVideoSection(),
              SizedBox(height: 32.h),

              // 提交按钮
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          '完成',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
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
            color: const Color(0xFF451A03),
          ),
        ),
        if (required)
          Text(
            ' *',
            style: TextStyle(fontSize: 14.sp, color: Colors.red),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFFFFBEB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFFEF3C7),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF451A03),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建照片网格
  Widget _buildPhotoGrid() {
    final itemWidth = (MediaQuery.of(context).size.width - 48.w) / 3; // 3列，减去左右padding和间距

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        // 已上传的照片
        ..._imageUrls.asMap().entries.map((entry) {
          final index = entry.key;
          final url = entry.value;
          return SizedBox(
            width: itemWidth,
            height: itemWidth,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    url,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // 删除按钮
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        // 添加按钮
        if (_imageUrls.length < 6)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: itemWidth,
              height: itemWidth,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFFFEF3C7),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 32.w,
                    color: const Color(0xFFF59E0B),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '添加照片',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 构建视频区域
  Widget _buildVideoSection() {
    if (_videoUrl != null) {
      return Stack(
        children: [
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 48.w,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '视频已上传',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 删除按钮
          Positioned(
            top: 8.h,
            right: 8.w,
            child: GestureDetector(
              onTap: _removeVideo,
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 20.w,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return GestureDetector(
        onTap: _pickVideo,
        child: Container(
          height: 120.h,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFFEF3C7),
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: 48.w,
                  color: const Color(0xFFF59E0B),
                ),
                SizedBox(height: 8.h),
                Text(
                  '添加视频',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '最长60秒',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
