import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/utils/toast.dart';

class RegisterPage extends StatefulWidget {
  final String? phone;
  const RegisterPage({super.key, this.phone});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    if (widget.phone != null && widget.phone!.isNotEmpty) {
      _phoneCtrl.text = widget.phone!;
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      Toast.error('请输入手机号');
      return;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      Toast.error('请输入正确手机号（11位）');
      return;
    }
    if (_countdown > 0) return;

    setState(() => _loading = true);
    try {
      final result = await ApiService().sendOtp(phone);
      Toast.success(result['message'] ?? '验证码已发送');
      // 开发环境显示验证码
      if (result['data']?['code'] != null) {
        Toast.success('验证码：${result['data']['code']}');
      }
      setState(() => _countdown = 60);
      _startCountdown();
    } catch (e) {
      Toast.error('发送失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      }
    });
  }



  Future<void> _confirmRegister() async {
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final pwd = _pwdCtrl.text;

    if (phone.isEmpty) {
      Toast.error('请输入手机号');
      return;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      Toast.error('请输入正确手机号（11位）');
      return;
    }
    if (code.isEmpty) {
      Toast.error('请输入验证码');
      return;
    }
    if (pwd.length < 6) {
      Toast.error('请输入至少 6 位密码');
      return;
    }

    setState(() => _loading = true);
    try {
      // 先验证验证码
      final verifyResult = await ApiService().verifyOtp(phone, code);
      if (verifyResult['code'] != 200) {
        Toast.error(verifyResult['message'] ?? '验证码验证失败');
        return;
      }

      if (!(verifyResult['data']?['isNewUser'] ?? false)) {
        Toast.error('手机号已注册，请直接登录');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // 验证码通过后，注册账号
      final registerResult = await ApiService().register(phone, pwd);
      if (!mounted) return;

      if (registerResult['code'] == 200) {
        Toast.success(registerResult['message'] ?? '注册成功');
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        Toast.error(registerResult['message'] ?? '注册失败');
      }
    } catch (e) {
      Toast.error('注册失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7).withOpacity(0.5),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7).withOpacity(0.5),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF451A03)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: 10.h),
                          // Logo Section
                          Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.r),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFDC700), Color(0xFFFE9A00)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFE9A00).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(Icons.pets, size: 40.w, color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            '创建账号',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF451A03),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '加入宠友，分享爱宠时光',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: const Color(0xFF92400E).withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 32.h),

                          // Register Form
                          Container(
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF92400E).withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '手机号',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF451A03),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(fontSize: 16.sp, color: const Color(0xFF451A03)),
                                  decoration: InputDecoration(
                                    hintText: '请输入手机号',
                                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                                    prefixIcon: Icon(Icons.phone_android_rounded, color: const Color(0xFFF59E0B), size: 20.w),
                                    filled: true,
                                    fillColor: const Color(0xFFFFFBEB),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  '验证码',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF451A03),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _codeCtrl,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        style: TextStyle(fontSize: 16.sp, color: const Color(0xFF451A03)),
                                        decoration: InputDecoration(
                                          hintText: '请输入验证码',
                                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                                          prefixIcon: Icon(Icons.sms_outlined, color: const Color(0xFFF59E0B), size: 20.w),
                                          filled: true,
                                          fillColor: const Color(0xFFFFFBEB),
                                          counterText: '',
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                            borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                            borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    SizedBox(
                                      width: 110.w,
                                      height: 50.h, // Match input height roughly
                                      child: ElevatedButton(
                                        onPressed: _countdown > 0 ? null : _sendOtp,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFFFBEB),
                                          foregroundColor: const Color(0xFFF59E0B),
                                          elevation: 0,
                                          side: const BorderSide(color: Color(0xFFFEF3C7)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text(
                                          _countdown > 0 ? '${_countdown}s' : '获取验证码',
                                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  '密码',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF451A03),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                TextFormField(
                                  controller: _pwdCtrl,
                                  obscureText: true,
                                  style: TextStyle(fontSize: 16.sp, color: const Color(0xFF451A03)),
                                  decoration: InputDecoration(
                                    hintText: '设置密码（至少6位）',
                                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                                    prefixIcon: Icon(Icons.lock_outline_rounded, color: const Color(0xFFF59E0B), size: 20.w),
                                    filled: true,
                                    fillColor: const Color(0xFFFFFBEB),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 32.h),

                                // Register Button
                                Container(
                                  width: double.infinity,
                                  height: 50.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFDC700), Color(0xFFFE9A00)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFE9A00).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _confirmRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                    ),
                                    child: _loading
                                        ? SizedBox(
                                            width: 24.w,
                                            height: 24.w,
                                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : Text(
                                            '确认注册',
                                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '已有账号？',
                                style: TextStyle(fontSize: 14.sp, color: const Color(0xFF92400E)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                child: Text(
                                  '立即登录',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            '注册即表示同意用户协议和隐私政策',
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[400]),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
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
}
