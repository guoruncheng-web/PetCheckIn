import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ScreenUtil 初始化封装（基于设计稿 375x812）
class ScreenUtilInitWrapper extends StatelessWidget {
  final Widget child;

  const ScreenUtilInitWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 尺寸
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => child,
    );
  }
}