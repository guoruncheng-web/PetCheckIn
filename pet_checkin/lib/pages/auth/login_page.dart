import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pet_checkin/services/supabase_service.dart';
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
      await SupabaseService.instance.signInWithPhonePassword(phone: phone, password: pwd);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFBEB), Color(0xFFFEFCE8), Color(0xFFFFF7ED)],
          ),
        ),
        child: SingleChildScrollView(child: Column(children: [
          SizedBox(height: 99.h),
          Container(
            width: 96.w,
            height: 96.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
                BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4)),
              ],
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFDC700), Color(0xFFFE9A00)]),
            ),
            child: Center(
              child: ScaleTransition(
                scale: _iconScale,
                child: Icon(Icons.pets, size: 48.w, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text('宠友', style: TextStyle(fontSize: 16.sp, color: const Color(0xFFE17100))),
          SizedBox(height: 8.h),
          Text('记录爱宠的每一天', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF92400E))),
          SizedBox(height: 32.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFFFF085), width: 1),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 25, offset: Offset(0, 20)),
                  BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 8)),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('登录', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF0A0A0A), fontWeight: FontWeight.w500)),
                  SizedBox(height: 6.h),
                  Text('使用手机号登录您的账号', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF92400E))),
                  SizedBox(height: 24.h),
                  Text('手机号', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF0A0A0A), fontWeight: FontWeight.w500)),
                  SizedBox(height: 8.h),
                  Container(
                    height: 36.h,
                    decoration: BoxDecoration(color: const Color(0xFFFFFBE8), border: Border.all(color: const Color(0xFFFFF085), width: 1), borderRadius: BorderRadius.circular(10.r)),
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '请输入手机号',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('密码', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF0A0A0A), fontWeight: FontWeight.w500)),
                  SizedBox(height: 8.h),
                  Container(
                    height: 36.h,
                    decoration: BoxDecoration(color: const Color(0xFFFFFBE8), border: Border.all(color: const Color(0xFFFFF085), width: 1), borderRadius: BorderRadius.circular(10.r)),
                    child: TextField(
                      controller: _pwdCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: '请输入密码',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    height: 36.h,
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _loading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFE9A00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))), child: const Text('登录', style: TextStyle(color: Colors.white))),
                  ),
                  SizedBox(height: 16.h),
                  Divider(color: const Color(0xFFFEF9C2)),
                  SizedBox(height: 8.h),
                  Center(child: TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text('立即注册 →'))),
                  SizedBox(height: 16.h),
                  Center(child: Text('登录即表示同意用户协议和隐私政策', style: TextStyle(fontSize: 13.sp, color: const Color(0xFF777777))))
                ]),
              ),
            ),
        ])),
      ),
    );
  }
}
