import 'package:flutter/material.dart';
import 'package:pet_checkin/ui/theme/app_theme.dart';
import 'package:pet_checkin/ui/utils/screen_adapter.dart';
import 'package:pet_checkin/services/api_service.dart';
import 'package:pet_checkin/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 API Service
  await ApiService().init();

  runApp(
    ScreenUtilInitWrapper(
      child: const PetCheckinApp(),
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
      initialRoute: '/',
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
