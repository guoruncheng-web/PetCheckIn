import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pet_checkin/services/location_service.dart';
import 'package:pet_checkin/pages/auth/widgets/city_selector.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/providers/user_provider.dart';
import 'package:pet_checkin/utils/toast.dart';

/// 完善个人资料弹窗
class CompleteProfileDialog extends StatefulWidget {
  const CompleteProfileDialog({super.key});

  @override
  State<CompleteProfileDialog> createState() => _CompleteProfileDialogState();
}

class _CompleteProfileDialogState extends State<CompleteProfileDialog> {
  final _nicknameCtrl = TextEditingController();
  String? _gender;
  DateTime? _birthday;
  String? _cityCode;
  String? _cityName;
  bool _isLocating = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 自动获取GPS位置
    _autoLocate();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  /// 自动获取GPS定位
  Future<void> _autoLocate() async {
    setState(() => _isLocating = true);
    try {
      final cityInfo = await LocationService.getCurrentCity();
      if (cityInfo != null && mounted) {
        setState(() {
          _cityCode = cityInfo['cityCode'];
          _cityName = cityInfo['cityName'];
        });
      }
    } catch (e) {
      debugPrint('自动定位失败: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// 手动选择城市
  Future<void> _selectCity() async {
    final selected = await showCitySelector(context);
    if (selected != null && mounted) {
      setState(() {
        _cityCode = selected.code;
        _cityName = selected.name;
      });
    }
  }

  /// 选择生日
  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '选择生日',
      cancelText: '取消',
      confirmText: '确定',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF59E0B), // 主色调（橙色）
              onPrimary: Colors.white, // 主色调上的文字颜色
              onSurface: Color(0xFF451A03), // 日期文字颜色
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B), // 按钮文字颜色
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

  /// 确认提交对话框
  Future<void> _confirmSubmit() async {
    final nickname = _nicknameCtrl.text.trim();

    // 至少填写昵称
    if (nickname.isEmpty) {
      Toast.error('请输入昵称');
      return;
    }

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认提交'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('昵称：$nickname'),
            if (_gender != null) Text('性别：${_gender == 'male' ? '男' : '女'}'),
            if (_birthday != null)
              Text('生日：${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'),
            if (_cityName != null) Text('城市：$_cityName'),
            const SizedBox(height: 12),
            const Text(
              '确认提交以上信息吗？',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 提交表单
    await _submit();
  }

  /// 提交表单
  Future<void> _submit() async {
    final nickname = _nicknameCtrl.text.trim();

    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService().updateMyProfile(
        nickname: nickname,
        gender: _gender,
        birthday: _birthday,
        cityCode: _cityCode,
        cityName: _cityName,
      );

      if (!mounted) return;

      if (result['code'] == 200) {
        // 刷新用户信息
        final userProvider = context.read<UserProvider>();
        await userProvider.fetchProfile();

        Toast.success('资料完善成功');
        Navigator.pop(context, true);
      } else {
        Toast.error(result['message'] ?? '提交失败');
      }
    } catch (e) {
      Toast.error('提交失败：$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 禁止返回关闭弹窗
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                '完善个人资料',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF451A03),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '请填写昵称以继续使用',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 24.h),

              // 昵称
              _buildLabel('昵称', required: true),
              SizedBox(height: 8.h),
              TextField(
                controller: _nicknameCtrl,
                decoration: InputDecoration(
                  hintText: '请输入昵称',
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
              SizedBox(height: 20.h),

              // 性别
              _buildLabel('性别'),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderButton('男', 'male'),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildGenderButton('女', 'female'),
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

              // 城市
              _buildLabel('所在城市'),
              SizedBox(height: 8.h),
              InkWell(
                onTap: _selectCity,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFEF3C7)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: const Color(0xFFF59E0B), size: 20.w),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _isLocating
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '正在定位...',
                                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
                                  ),
                                ],
                              )
                            : Text(
                                _cityName ?? '请选择城市',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: _cityName != null ? const Color(0xFF451A03) : Colors.grey[400],
                                ),
                              ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 20.w),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmSubmit,
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
}

/// 显示完善资料弹窗
Future<bool?> showCompleteProfileDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CompleteProfileDialog(),
  );
}
