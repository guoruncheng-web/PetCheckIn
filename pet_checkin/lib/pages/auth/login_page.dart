import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/utils/toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _iconScale = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut));
  }

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    if (phone.isEmpty) {
      Toast.error('请输入手机号');
      return;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      Toast.error('请输入正确手机号（11位）');
      return;
    }
    if (pwd.length < 6) {
      Toast.error('请输入至少 6 位密码');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService().login(phone, pwd);
      if (!mounted) return;
      if (result['success']) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        Toast.error('登录失败');
      }
    } catch (e) {
      Toast.error('登录失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _iconCtrl.dispose();
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
                  gradient: RadialGradient(
                    colors: [const Color(0xFFFEF3C7).withOpacity(0.6), const Color(0xFFFEF3C7).withOpacity(0)],
                  ),
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
                  gradient: RadialGradient(
                    colors: [const Color(0xFFFDE68A).withOpacity(0.4), const Color(0xFFFDE68A).withOpacity(0)],
                  ),
                ),
              ),
            ),
             Positioned(
              top: 150,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFFBEB).withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60.h),
                    // Logo Section
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.r),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFDC700), Color(0xFFFE9A00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFE9A00).withOpacity(0.5),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: ScaleTransition(
                          scale: _iconScale,
                          child: Icon(Icons.pets, size: 50.w, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      '欢迎回来',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF451A03),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '登录您的宠友账号',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: const Color(0xFF92400E).withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    
                    // Login Form
                    Container(
                      padding: EdgeInsets.all(32.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32.r),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF92400E).withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
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
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF451A03),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF451A03), fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: '请输入手机号',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                              prefixIcon: Icon(Icons.phone_android_rounded, color: const Color(0xFFF59E0B), size: 20.w),
                              filled: true,
                              fillColor: const Color(0xFFFFFBEB),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            '密码',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF451A03),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          TextFormField(
                            controller: _pwdCtrl,
                            obscureText: true,
                            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF451A03), fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: '请输入密码',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: const Color(0xFFF59E0B), size: 20.w),
                              filled: true,
                              fillColor: const Color(0xFFFFFBEB),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                              ),
                            ),
                          ),
                          SizedBox(height: 32.h),
                          
                          // Login Button
                          Container(
                            width: double.infinity,
                            height: 54.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFDC700), Color(0xFFFE9A00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFE9A00).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                              ),
                              child: _loading
                                  ? SizedBox(
                                      width: 24.w,
                                      height: 24.w,
                                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      '登 录',
                                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
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
                          '还没有账号？',
                          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF92400E), fontWeight: FontWeight.w500),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: Text(
                            '立即注册',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      '登录即表示同意用户协议和隐私政策',
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
    );
  }
}
