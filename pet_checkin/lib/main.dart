import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pet_checkin/ui/theme/app_theme.dart';
import 'package:pet_checkin/ui/utils/screen_adapter.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/providers/user_provider.dart';
import 'package:pet_checkin/routes.dart';

// Global navigator key for Toast
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 API Service
  await ApiService().init();

  // 初始化 UserProvider 并从缓存加载用户信息
  final userProvider = UserProvider();
  await userProvider.loadFromCache();

  // 如果有 token，尝试刷新用户信息
  if (ApiService().isLoggedIn) {
    userProvider.fetchProfile();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: ScreenUtilInitWrapper(
        child: const PetCheckinApp(),
      ),
    ),
  );
}

class PetCheckinApp extends StatelessWidget {
  const PetCheckinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '宠物打卡',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      navigatorKey: navigatorKey,
      initialRoute: '/',
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        // 添加 Alice 悬浮按钮（仅在 Debug 模式下显示）
        return Stack(
          children: [
            child!,
            if (const bool.fromEnvironment('dart.vm.product') == false)
              Positioned(
                bottom: 100,
                right: 20,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.blue.withOpacity(0.8),
                  onPressed: () {
                    ApiService().alice.showInspector();
                  },
                  child: const Icon(Icons.network_check, size: 20),
                ),
              ),
          ],
        );
      },
    );
  }
}
