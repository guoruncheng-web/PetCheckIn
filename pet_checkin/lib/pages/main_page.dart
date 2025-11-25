import 'package:flutter/material.dart';
import 'package:pet_checkin/pages/home/home_page.dart';
import 'package:pet_checkin/pages/square/square_page.dart';
import 'package:pet_checkin/pages/profile/profile_page.dart';
import 'package:pet_checkin/ui/components/app_bottom_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SquarePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _pages[_currentIndex],
      bottomNavigationBar: AppBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}