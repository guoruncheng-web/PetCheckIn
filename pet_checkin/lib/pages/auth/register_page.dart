import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pet_checkin/services/supabase_service.dart';
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
      await SupabaseService.instance.sendOtp(phone: phone);
      Toast.success('验证码已发送');
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
    if (!SupabaseService.instance.isConfigProvided) {
      Toast.error('请配置 SUPABASE_URL 与 SUPABASE_ANON_KEY');
      return;
    }
    final ok = await SupabaseService.instance.quickConnectivityCheck();
    if (!ok) {
      Toast.error('网络异常或证书问题，无法连接 Supabase');
      return;
    }

    setState(() => _loading = true);
    try {
      // 先验证验证码
      final isNew = await SupabaseService.instance.verifyOtp(phone: phone, code: code);
      if (!isNew) {
        Toast.error('手机号已注册，请直接登录');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // 验证码通过后，注册账号
      await SupabaseService.instance.signUpWithPhonePassword(phone: phone, password: pwd);
      if (!mounted) return;
      Toast.success('注册成功');
      Navigator.pushReplacementNamed(context, '/main');
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFBEB), Color(0xFFFEFCE8), Color(0xFFFFF7ED)],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 79.h),
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
              child: Icon(Icons.pets, size: 48.w, color: Colors.white),
            ),
            SizedBox(height: 16.h),
            Text('宠友', style: TextStyle(fontSize: 16.sp, color: const Color(0xFFE17100))),
            SizedBox(height: 8.h),
            Text('加入宠友，分享爱宠时光', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF92400E))),
            SizedBox(height: 32.h),
            Expanded(
              child: Container(
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0A0A0A)),
                          ),
                          SizedBox(width: 8.w),
                          Text('注册账号', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF0A0A0A))),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Text('创建您的宠友账号', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF92400E))),
                      SizedBox(height: 16.h),
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
                      SizedBox(height: 8.h),
                      Text('手机号将作为您的登录账号', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF92400E))),
                      SizedBox(height: 16.h),
                      Text('验证码', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF0A0A0A), fontWeight: FontWeight.w500)),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36.h,
                              decoration: BoxDecoration(color: const Color(0xFFFFFBE8), border: Border.all(color: const Color(0xFFFFF085), width: 1), borderRadius: BorderRadius.circular(10.r)),
                              child: TextField(
                                controller: _codeCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: const InputDecoration(
                                  hintText: '请输入验证码',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  counterText: '',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          SizedBox(
                            width: 100.w,
                            height: 36.h,
                            child: TextButton(
                              onPressed: _countdown > 0 ? null : _sendOtp,
                              style: TextButton.styleFrom(
                                backgroundColor: _countdown > 0 ? Colors.grey.shade300 : const Color(0xFFFE9A00),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                _countdown > 0 ? '${_countdown}s' : '获取验证码',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            ),
                          ),
                        ],
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
                            hintText: '请输入密码（至少6位）',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        height: 36.h,
                        width: double.infinity,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.r), gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFFFDC700), Color(0xFFFE9A00)]), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4)), BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))]),
                        child: ElevatedButton(onPressed: _loading ? null : _confirmRegister, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))), child: const Text('确认注册', style: TextStyle(color: Colors.white))),
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.only(top: 16.h),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFFEF9C2), width: 1))),
                        child: Column(children: [
                          Text('已有账号？', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF92400E))),
                          SizedBox(height: 8.h),
                          TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('立即登录 →', style: TextStyle(color: Color(0xFFE17100))))
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text('注册即表示同意用户协议和隐私政策', style: TextStyle(fontSize: 13.sp, color: const Color(0xFF777777))),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
