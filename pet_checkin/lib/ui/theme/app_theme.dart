import 'package:flutter/material.dart';

/// 全局主题配置
class AppTheme {
  AppTheme._();

  // 主色调 - 温暖活泼的宠物主题
  static const Color primary = Color(0xFFF59E0B);   // 主橙色
  static const Color primaryLight = Color(0xFFFFD4A3); // 浅橙色
  static const Color primaryDark = Color(0xFFEA580C);  // 深橙色
  
  static const Color secondary = Color(0xFF4CAF50); // 绿色（打卡成功）
  static const Color accent = Color(0xFFFF9AC7);    // 粉色（可爱点缀）
  
  // 背景色系 - 温暖柔和
  static const Color background = Color(0xFFFFFBF5);      // 奶白色背景
  static const Color backgroundLight = Color(0xFFFFFFF8); // 更浅的背景
  static const Color surface = Colors.white;              // 卡片表面
  static const Color surfaceVariant = Color(0xFFFFF8ED);  // 变体表面
  
  // 功能色
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF64B5F6);

  // 文字颜色
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF78350F);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // 渐变色组 - 用于卡片装饰
  static const List<Color> gradientWarmOrange = [
    Color(0xFFFFE5B4),
    Color(0xFFFFD4A3),
    Color(0xFFFFE8CC),
  ];
  
  static const List<Color> gradientPink = [
    Color(0xFFFCE4EC),
    Color(0xFFF8BBD0),
  ];
  
  static const List<Color> gradientBlue = [
    Color(0xFFE3F2FD),
    Color(0xFFBBDEFB),
  ];
  
  static const List<Color> gradientPurple = [
    Color(0xFFF3E5F5),
    Color(0xFFE1BEE7),
  ];
  
  static const List<Color> gradientGreen = [
    Color(0xFFE8F5E9),
    Color(0xFFC8E6C9),
  ];
  
  static const List<Color> gradientYellow = [
    Color(0xFFFFF9C4),
    Color(0xFFFFF59D),
  ];
  
  // 宠物卡片渐变色集合
  static const List<List<Color>> petCardGradients = [
    [Color(0xFFFFF4E6), Color(0xFFFFE8CC)], // 温暖橙
    [Color(0xFFFCE4EC), Color(0xFFF8BBD0)], // 粉红色
    [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // 天蓝色
    [Color(0xFFF3E5F5), Color(0xFFE1BEE7)], // 淡紫色
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], // 薄荷绿
    [Color(0xFFFFF9C4), Color(0xFFFFF59D)], // 柠檬黄
  ];

  // 圆角
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  // 阴影
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // 文字样式
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.3,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.4,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  // 亮色主题
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
        ),
        scaffoldBackgroundColor: background,
        canvasColor: background,
        dialogBackgroundColor: surface,
        dividerColor: Color(0xFFFFE8CC).withValues(alpha: 0.3),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: surface,
          foregroundColor: textPrimary,
          centerTitle: true,
          titleTextStyle: titleLarge,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            textStyle: bodyLarge.copyWith(fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: primary),
            textStyle: bodyLarge.copyWith(fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: error),
          ),
        ),
      );

  // 暗色主题（后续再细化）
  static ThemeData get dark => light; // 先复用，后续再写
}