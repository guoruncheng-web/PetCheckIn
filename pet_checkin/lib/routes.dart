import 'package:flutter/material.dart';
import 'package:pet_checkin/ui/pages/splash_page.dart';
import 'package:pet_checkin/pages/auth/login_page.dart';
import 'package:pet_checkin/pages/auth/register_page.dart';
import 'package:pet_checkin/pages/auth/forgot_password_page.dart';
import 'package:pet_checkin/pages/main_page.dart';
import 'package:pet_checkin/pages/home/home_page.dart';
import 'package:pet_checkin/pages/square/square_page.dart';
import 'package:pet_checkin/pages/profile/profile_page.dart';
import 'package:pet_checkin/pages/pet/add_pet_page.dart';
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/pages/myPets/my_pets_page.dart';
import 'package:pet_checkin/pages/Info/person_info.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/main';
  static const String home = '/home';
  static const String square = '/square';
  static const String profile = '/profile';
  static const String addPet = '/add_pet';
  static const String petDetail = '/pet_detail';
  static const String myPets = '/my_pets';
  static const String myInfo = '/my_info';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        final phone = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => RegisterPage(phone: phone));
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case main:
        return MaterialPageRoute(builder: (_) => const MainPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case square:
        return MaterialPageRoute(builder: (_) => const SquarePage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case addPet:
        return MaterialPageRoute(builder: (_) => const AddPetPage());
      case petDetail:
        final pet = settings.arguments as Pet?;
        return MaterialPageRoute(builder: (_) => AddPetPage(pet: pet));
      case myPets:
        return MaterialPageRoute(builder: (_) => const MyPetsPage());
      case myInfo:
        return MaterialPageRoute(builder: (_) => const MyInfo());
      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}
