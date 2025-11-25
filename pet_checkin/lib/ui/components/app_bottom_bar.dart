import 'package:flutter/material.dart';
import '../utils/ui_kit.dart';

/// 三段式底部导航
class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SalomonBottomBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        SalomonBottomBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          title: const Text('首页'),
          selectedColor: Theme.of(context).colorScheme.primary,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.explore_outlined),
          activeIcon: const Icon(Icons.explore),
          title: const Text('广场'),
          selectedColor: Theme.of(context).colorScheme.primary,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          title: const Text('我的'),
          selectedColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}