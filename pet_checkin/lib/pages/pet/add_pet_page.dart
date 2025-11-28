import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/utils/toast.dart';
import 'package:pet_checkin/models/pet.dart';
import 'package:video_player/video_player.dart';

/// 添加/编辑宠物页面
class AddPetPage extends StatefulWidget {
  final Pet? pet; // 如果传入 pet，则为编辑模式

  const AddPetPage({super.key, this.pet});

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
  VideoPlayerController? _videoController;

  bool get _isEditMode => widget.pet != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // 编辑模式：回显数据
      final pet = widget.pet!;
      _nameController.text = pet.name;
      _breedController.text = pet.breed ?? '';
      _weightController.text = pet.weightKg?.toString() ?? '';
      _descriptionController.text = pet.description ?? '';
      _avatarUrl = pet.avatarUrl;
      _gender = pet.gender ?? 'MALE';
      _birthday = pet.birthday;

      // 回显图片和视频
      if (pet.imageUrls != null && pet.imageUrls!.isNotEmpty) {
        _imageUrls.addAll(pet.imageUrls!);
      }
      if (pet.videoUrl != null) {
        _videoUrl = pet.videoUrl;
        _initVideoPlayer(pet.videoUrl!);
      }
    }
  }

  /// 初始化视频播放器（只加载第一帧，不自动播放）
  Future<void> _initVideoPlayer(String url) async {
    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      if (mounted) {
        setState(() {});
        // 不自动播放，只显示第一帧
      }
    } catch (error) {
      print('视频加载失败：$error');
      // 在 iOS 模拟器上视频播放可能失败，但不影响功能
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
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
      final uploadResult =
          await ApiService().uploadFile(image.path, 'pet_avatar');

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
        final uploadResult =
            await ApiService().uploadFile(image.path, 'pet_photo');

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
      final uploadResult =
          await ApiService().uploadFile(video.path, 'pet_video');

      if (uploadResult['code'] != 200) {
        Toast.error(uploadResult['message'] ?? '上传失败');
        return;
      }

      final videoUrl = uploadResult['data']['url'];
      setState(() {
        _videoUrl = videoUrl;
      });

      // 初始化视频播放器
      await _initVideoPlayer(videoUrl);

      Toast.success('视频上传成功');
    } catch (e) {
      Toast.error('视频上传失败：$e');
    }
  }

  /// 删除视频
  void _removeVideo() {
    _videoController?.dispose();
    _videoController = null;
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
      final Map<String, dynamic> result;

      if (_isEditMode) {
        // 编辑模式：调用更新接口
        result = await ApiService().updatePet(
          petId: widget.pet!.id,
          name: _nameController.text.trim(),
          breed: _breedController.text.trim(),
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
      } else {
        // 新增模式：调用创建接口
        result = await ApiService().createPet(
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
      }

      if (!mounted) return;

      if (result['code'] == 200 || result['code'] == 201) {
        Toast.success(_isEditMode ? '宠物信息已更新' : '宠物添加成功');
        Navigator.pop(context, true); // 返回 true 表示操作成功
      } else {
        Toast.error(result['message'] ?? (_isEditMode ? '更新失败' : '添加失败'));
      }
    } catch (e) {
      Toast.error('${_isEditMode ? '更新' : '添加'}失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // 渐变头部区域
            SliverAppBar(
              expandedHeight: 290.h,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF451A03),
              elevation: 0,
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
                    bottom: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 20.h),
                          // 头像
                          GestureDetector(
                          onTap: _pickAvatar,
                          child: Hero(
                            tag: 'pet_avatar_${widget.pet?.id ?? 'new'}',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.orange.shade300.withOpacity(0.4),
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
                                          color: Colors.white, width: 4),
                                    ),
                                    child: ClipOval(
                                      child: _avatarUrl != null
                                          ? Image.network(
                                              _avatarUrl!,
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
                                                Icons.pets,
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
                                            Color(0xFFF59E0B)
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
                        // 标题
                        Text(
                          _isEditMode ? '编辑宠物' : '添加宠物',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF451A03),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        ],
                      ),
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
                      icon: Icons.info_outline,
                      children: [
                        _buildLabel('宠物名称', required: true),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _nameController,
                          decoration:
                              _inputDecoration('请输入宠物名称', icon: Icons.pets),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入宠物名称';
                            }
                            return null;
                          },
                          onChanged: (value) => setState(() {}), // 更新头部显示
                        ),
                        SizedBox(height: 20.h),
                        _buildLabel('品种', required: true),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _breedController,
                          decoration: _inputDecoration('如：金毛、泰迪、英短等',
                              icon: Icons.category_outlined),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入宠物品种';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),
                        _buildLabel('性别'),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(child: _buildGenderButton('男生', 'MALE')),
                            SizedBox(width: 12.w),
                            Expanded(child: _buildGenderButton('女生', 'FEMALE')),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // 详细信息卡片
                    _buildSectionCard(
                      title: '详细信息',
                      icon: Icons.description_outlined,
                      children: [
                        _buildLabel('生日'),
                        SizedBox(height: 12.h),
                        InkWell(
                          onTap: _selectBirthday,
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFFFF3E0),
                                  Colors.orange.shade50
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                  color: Colors.orange.shade200, width: 1.5),
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
                                  child: Icon(Icons.cake_rounded,
                                      color: const Color(0xFFF59E0B),
                                      size: 24.w),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('生日',
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.brown.shade600)),
                                      SizedBox(height: 4.h),
                                      Text(
                                        _birthday != null
                                            ? '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'
                                            : '请选择生日',
                                        style: TextStyle(
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w600,
                                          color: _birthday != null
                                              ? const Color(0xFF451A03)
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.orange.shade400, size: 28.w),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildLabel('体重 (kg)'),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _weightController,
                          decoration: _inputDecoration('如：5.5',
                              icon: Icons.monitor_weight_outlined),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                        SizedBox(height: 20.h),
                        _buildLabel('宠物简介'),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _inputDecoration('介绍一下你的宠物吧~',
                              icon: Icons.edit_note_rounded),
                          maxLines: 4,
                          maxLength: 200,
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // 照片和视频卡片
                    _buildSectionCard(
                      title: '照片和视频',
                      icon: Icons.photo_library_outlined,
                      children: [
                        _buildLabel('照片（最多6张）'),
                        SizedBox(height: 12.h),
                        _buildPhotoGrid(),
                        SizedBox(height: 24.h),
                        _buildLabel('视频（最多1个）'),
                        SizedBox(height: 12.h),
                        _buildVideoSection(),
                      ],
                    ),

                    SizedBox(height: 32.h),

                    // 提交按钮
                    Container(
                      height: 52.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB74D), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r)),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 22.w),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _isEditMode ? '保存修改' : '完成添加',
                                    style: TextStyle(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                  Colors.orange.shade50.withOpacity(0.3)
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
                  child: Icon(icon, color: const Color(0xFFF59E0B), size: 20.w),
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
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15.sp),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _gender == value;
    final isDisabled = _isEditMode; // 编辑模式下禁用性别修改

    // 编辑模式下，如果是当前性别，显示高亮；否则灰色
    // 新增模式下，正常显示选中状态
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isDisabled) {
      // 编辑模式
      if (isSelected) {
        backgroundColor = const Color(0xFFF59E0B);
        borderColor = const Color(0xFFF59E0B);
        textColor = Colors.white;
      } else {
        backgroundColor = Colors.grey.shade200;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade500;
      }
    } else {
      // 新增模式
      backgroundColor =
          isSelected ? const Color(0xFFF59E0B) : const Color(0xFFFFFBEB);
      borderColor =
          isSelected ? const Color(0xFFF59E0B) : const Color(0xFFFEF3C7);
      textColor = isSelected ? Colors.white : const Color(0xFF451A03);
    }

    return InkWell(
      onTap: isDisabled ? null : () => setState(() => _gender = value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建照片网格
  Widget _buildPhotoGrid() {
    final itemWidth =
        (MediaQuery.of(context).size.width - 48.w) / 3; // 3列，减去左右padding和间距

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
                GestureDetector(
                  onTap: () => _previewImage(url, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      url,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
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
          GestureDetector(
            onTap: () => _previewVideo(_videoUrl!),
            child: Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: _videoController != null &&
                        _videoController!.value.isInitialized
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                          // 播放按钮覆盖层
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 64.w,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Center(
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
                              _videoController == null ? '视频已上传' : '加载中...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  /// 预览图片（支持左右滑动切换）
  void _previewImage(String url, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImagePreviewPage(
          imageUrls: _imageUrls,
          initialIndex: index,
        ),
      ),
    );
  }

  /// 预览视频
  void _previewVideo(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _VideoPreviewPage(videoUrl: url),
      ),
    );
  }
}

/// 图片预览页面（支持左右滑动）
class _ImagePreviewPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImagePreviewPage({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<_ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1}/${widget.imageUrls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.network(widget.imageUrls[index]),
            ),
          );
        },
      ),
    );
  }
}

/// 视频预览页面
class _VideoPreviewPage extends StatefulWidget {
  final String videoUrl;

  const _VideoPreviewPage({required this.videoUrl});

  @override
  State<_VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<_VideoPreviewPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.play();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('视频加载失败：$e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('视频预览'),
      ),
      body: Center(
        child: _isInitialized
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
