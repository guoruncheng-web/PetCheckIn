import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:video_player/video_player.dart';

class CheckInPage extends StatefulWidget {
  final Position position;

  const CheckInPage({
    super.key,
    required this.position,
  });

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final TextEditingController _moodController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _images = [];
  XFile? _video;
  VideoPlayerController? _videoController;
  List<String> _selectedTags = [];
  String _locationAddress = '获取地址中...';
  bool _isLoadingAddress = true;

  // 宠物相关
  List<Pet> _pets = [];
  Pet? _selectedPet;
  bool _loadingPets = true;

  // 预设标签
  final List<String> _presetTags = [
    '开心',
    '快乐',
    '散步',
    '玩耍',
    '吃饭',
    '睡觉',
    '训练',
    '洗澡',
    '看医生',
    '出游',
  ];

  @override
  void initState() {
    super.initState();
    _getAddressFromPosition();
    _loadPets();
  }

  @override
  void dispose() {
    _moodController.dispose();
    _customTagController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  /// 加载宠物列表
  Future<void> _loadPets() async {
    try {
      final result = await ApiService().getMyPets();

      if (mounted && result['code'] == 200) {
        final List<dynamic> petsData = result['data'] ?? [];
        final pets = petsData.map((json) => Pet.fromJson(json)).toList();

        setState(() {
          _pets = pets;
          _loadingPets = false;
          // 默认选择第一只宠物
          if (_pets.isNotEmpty) {
            _selectedPet = _pets.first;
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _pets = [];
            _loadingPets = false;
          });
        }
      }
    } catch (e) {
      print('获取宠物列表失败：$e');
      if (mounted) {
        setState(() {
          _pets = [];
          _loadingPets = false;
        });
        _showMessage('获取宠物列表失败');
      }
    }
  }

  /// 获取地址信息
  Future<void> _getAddressFromPosition() async {
    try {
      print('开始获取地址信息: ${widget.position.latitude}, ${widget.position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.position.latitude,
        widget.position.longitude,
      );

      print('获取到的地址数量: ${placemarks.length}');

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        print('地址详情: $place');
        print('国家: ${place.country}');
        print('省份: ${place.administrativeArea}');
        print('城市: ${place.locality}');
        print('区: ${place.subLocality}');
        print('街道: ${place.street}');
        print('门牌号: ${place.subThoroughfare}');

        // 组合地址信息
        String address = '';

        // 优先使用更详细的信息
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += place.locality!; // 城市
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ' ';
          address += place.subLocality!; // 区
        }

        // 使用 street（已包含完整街道信息）或 thoroughfare
        if (place.street != null && place.street!.isNotEmpty) {
          if (address.isNotEmpty) address += ' ';
          address += place.street!; // 完整街道（如 "1-99 Stockton St"）
        } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          if (address.isNotEmpty) address += ' ';
          address += place.thoroughfare!; // 街道名称

          // 如果有门牌号,单独添加
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            address += ' ${place.subThoroughfare!}';
          }
        }

        // 如果以上都没有,使用 name
        if (address.isEmpty && place.name != null && place.name!.isNotEmpty) {
          address = place.name!;
        }

        print('最终地址: $address');

        if (mounted) {
          setState(() {
            _locationAddress = address.isNotEmpty ? address : '位置未知';
            _isLoadingAddress = false;
          });
        }
      } else {
        print('未获取到地址信息');
        if (mounted) {
          setState(() {
            _locationAddress = '位置未知';
            _isLoadingAddress = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print('获取地址失败: $e');
      print('堆栈: $stackTrace');

      // 降级方案：显示"位置未知"而不是经纬度
      if (mounted) {
        setState(() {
          _locationAddress = '位置未知';
          _isLoadingAddress = false;
        });
      }
    }
  }

  /// 选择图片
  Future<void> _pickImages() async {
    if (_images.length >= 9) {
      _showMessage('最多只能选择9张图片');
      return;
    }

    try {
      final List<XFile> selectedImages = await _picker.pickMultiImage();

      // 计算可以添加的数量
      int availableSlots = 9 - _images.length;

      if (selectedImages.length > availableSlots) {
        _showMessage('最多只能选择9张图片，当前还可添加$availableSlots张');
        setState(() {
          _images.addAll(selectedImages.take(availableSlots));
        });
      } else {
        setState(() {
          _images.addAll(selectedImages);
        });
      }
    } catch (e) {
      _showMessage('选择图片失败: $e');
    }
  }

  /// 删除图片
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  /// 选择视频
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        // 释放旧的视频控制器
        await _videoController?.dispose();

        // 创建新的视频控制器
        final controller = VideoPlayerController.file(File(video.path));
        await controller.initialize();

        setState(() {
          _video = video;
          _videoController = controller;
        });
      }
    } catch (e) {
      _showMessage('选择视频失败: $e');
    }
  }

  /// 删除视频
  void _removeVideo() {
    _videoController?.dispose();
    setState(() {
      _video = null;
      _videoController = null;
    });
  }

  /// 切换标签选中状态
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  /// 添加自定义标签
  void _addCustomTag() {
    final customTag = _customTagController.text.trim();

    if (customTag.isEmpty) {
      _showMessage('请输入标签内容');
      return;
    }

    if (_selectedTags.contains(customTag)) {
      _showMessage('标签已存在');
      return;
    }

    setState(() {
      _selectedTags.add(customTag);
      _customTagController.clear();
    });
  }

  /// 提交打卡
  Future<void> _submitCheckIn() async {
    // 验证是否选择了宠物
    if (_selectedPet == null) {
      _showMessage('请选择要打卡的宠物');
      return;
    }

    final mood = _moodController.text.trim();

    if (mood.isEmpty) {
      _showMessage('请填写今日心情');
      return;
    }

    if (_images.isEmpty && _video == null) {
      _showMessage('请至少上传一张图片或一个视频');
      return;
    }

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFFF59E0B),
              ),
              SizedBox(height: 16.h),
              Text(
                '正在上传...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 1. 上传图片到OSS
      List<String> imageUrls = [];
      for (var image in _images) {
        try {
          final result = await ApiService().uploadFile(image.path, 'checkin');
          if (result['code'] == 200 && result['data'] != null) {
            imageUrls.add(result['data']['url']);
          }
        } catch (e) {
          print('上传图片失败: $e');
        }
      }

      // 2. 上传视频到OSS（如果有）
      String? videoUrl;
      if (_video != null) {
        try {
          final result = await ApiService().uploadFile(_video!.path, 'checkin-video');
          if (result['code'] == 200 && result['data'] != null) {
            videoUrl = result['data']['url'];
          }
        } catch (e) {
          print('上传视频失败: $e');
        }
      }

      // 3. 调用打卡API
      final checkInData = {
        'petId': _selectedPet!.id,
        'content': mood,
        'imageUrls': imageUrls,
        if (videoUrl != null) 'videoUrl': videoUrl,
        'tags': _selectedTags,
        if (_locationAddress != '获取地址中...' && _locationAddress != '位置未知')
          'address': _locationAddress,
        'latitude': widget.position.latitude,
        'longitude': widget.position.longitude,
        // TODO: 需要从地理位置获取城市代码和名称
      };

      final result = await ApiService().createCheckIn(checkInData);

      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();

      if (result['code'] == 201) {
        _showMessage('打卡成功！');
        // 延迟一下再返回，让用户看到成功提示
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context).pop(true); // 返回 true 表示打卡成功
      } else {
        _showMessage(result['message'] ?? '打卡失败');
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();
      _showMessage('打卡失败: $e');
      print('打卡错误: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 预览图片
  void _previewImage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImagePreviewPage(
          images: _images,
          initialIndex: index,
        ),
      ),
    );
  }

  /// 预览视频
  void _previewVideo() {
    if (_video != null && _videoController != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _VideoPreviewPage(
            videoPath: _video!.path,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('今日打卡'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF451A03),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _submitCheckIn,
            child: Text(
              '发布',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: _loadingPets
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 宠物选择
                  _buildPetSelector(),
                  SizedBox(height: 16.h),

                  // 位置信息提示
                  _buildLocationInfo(),
                  SizedBox(height: 16.h),

                  // 心情文案输入
                  _buildMoodInput(),
                  SizedBox(height: 16.h),

            // 图片选择区域
            _buildImagePicker(),
            SizedBox(height: 16.h),

            // 视频选择区域
            _buildVideoPicker(),
            SizedBox(height: 16.h),

            // 标签选择
            _buildTagSelector(),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  /// 宠物选择器
  Widget _buildPetSelector() {
    if (_pets.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.pets,
              size: 24.w,
              color: Colors.orange,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                '您还没有宠物，请先添加宠物',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.brown.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择宠物',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF451A03),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 100.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pets.length,
              itemBuilder: (context, index) {
                final pet = _pets[index];
                final isSelected = _selectedPet?.id == pet.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPet = pet;
                    });
                  },
                  child: Container(
                    width: 80.w,
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF59E0B)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 宠物头像
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
                                  color: isSelected
                                      ? const Color(0xFFF59E0B)
                                      : Colors.orange.shade200,
                                  child: Icon(
                                    Icons.pets,
                                    size: 20.w,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        SizedBox(height: 8.h),
                        // 宠物名字
                        Text(
                          pet.name,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFF59E0B)
                                : Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        // 选中标记
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 16.w,
                            color: const Color(0xFFF59E0B),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 位置信息
  Widget _buildLocationInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 20.w,
            color: const Color(0xFFF59E0B),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _isLoadingAddress
                ? Row(
                    children: [
                      SizedBox(
                        width: 12.w,
                        height: 12.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _locationAddress,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.brown.shade700,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _locationAddress,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.brown.shade700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 心情文案输入
  Widget _buildMoodInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日心情',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF451A03),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _moodController,
            maxLines: 5,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: '分享一下今天和宠物的快乐时光吧...',
              hintStyle: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFF59E0B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 图片选择器
  Widget _buildImagePicker() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '添加图片',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF451A03),
                ),
              ),
              Text(
                '${_images.length}/9',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
            ),
            itemCount: _images.length + (_images.length < 9 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _images.length) {
                // 添加按钮
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 32.w,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              }

              // 图片预览
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => _previewImage(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.file(
                        File(_images[index].path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4.w,
                    right: 4.w,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
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
              );
            },
          ),
        ],
      ),
    );
  }

  /// 视频选择器
  Widget _buildVideoPicker() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '添加视频（选填）',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF451A03),
            ),
          ),
          SizedBox(height: 12.h),
          if (_video == null)
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 100.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam,
                        size: 32.w,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '点击添加视频',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Stack(
              children: [
                GestureDetector(
                  onTap: _previewVideo,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: SizedBox(
                      height: 200.h,
                      width: double.infinity,
                      child: _videoController != null && _videoController!.value.isInitialized
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                // 视频第一帧作为缩略图
                                VideoPlayer(_videoController!),
                                // 半透明遮罩
                                Container(
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                                // 播放图标居中
                                Center(
                                  child: Icon(
                                    Icons.play_circle_filled,
                                    size: 48.w,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.videocam,
                                      size: 32.w,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 8.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                                      child: Text(
                                        _video!.name,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                // 删除按钮
                Positioned(
                  top: 8.w,
                  right: 8.w,
                  child: GestureDetector(
                    onTap: _removeVideo,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 标签选择器
  Widget _buildTagSelector() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '添加标签',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF451A03),
            ),
          ),
          SizedBox(height: 12.h),

          // 预设标签
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _presetTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => _toggleTag(tag),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    '# $tag',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 12.h),

          // 自定义标签输入
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTagController,
                  decoration: InputDecoration(
                    hintText: '自定义标签',
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: _addCustomTag,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: const Text('添加'),
              ),
            ],
          ),

          // 已选标签展示
          if (_selectedTags.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              '已选标签:',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _selectedTags.map((tag) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '# $tag',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: () => _toggleTag(tag),
                        child: Icon(
                          Icons.close,
                          size: 14.w,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// 图片预览页面
class _ImagePreviewPage extends StatefulWidget {
  final List<XFile> images;
  final int initialIndex;

  const _ImagePreviewPage({
    required this.images,
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
        title: Text('${_currentIndex + 1}/${widget.images.length}'),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(widget.images[index].path),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 视频预览页面
class _VideoPreviewPage extends StatefulWidget {
  final String videoPath;

  const _VideoPreviewPage({
    required this.videoPath,
  });

  @override
  State<_VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<_VideoPreviewPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _controller.initialize().then((_) {
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    });
    _controller.setLooping(true);
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
        elevation: 0,
      ),
      body: Center(
        child: _isInitialized
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    if (!_controller.value.isPlaying)
                      Icon(
                        Icons.play_circle_filled,
                        size: 64.w,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                  ],
                ),
              )
            : const CircularProgressIndicator(
                color: Colors.white,
              ),
      ),
    );
  }
}
