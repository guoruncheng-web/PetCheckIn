import 'package:flutter/material.dart';
import '../utils/ui_kit.dart';

/// 统一下拉刷新/上拉加载封装
class AppRefreshWrapper extends StatelessWidget {
  final RefreshController controller;
  final VoidCallback onRefresh;
  final VoidCallback? onLoading;
  final Widget child;
  final bool enablePullUp;

  const AppRefreshWrapper({
    super.key,
    required this.controller,
    required this.onRefresh,
    this.onLoading,
    required this.child,
    this.enablePullUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: controller,
      onRefresh: onRefresh,
      onLoading: onLoading,
      enablePullUp: enablePullUp,
      header: const WaterDropHeader(),
      footer: CustomFooter(
        builder: (context, mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = const Text('上拉加载更多');
          } else if (mode == LoadStatus.loading) {
            body = const CircularProgressIndicator(strokeWidth: 2);
          } else if (mode == LoadStatus.failed) {
            body = const Text('加载失败，请重试');
          } else if (mode == LoadStatus.canLoading) {
            body = const Text('松手加载更多');
          } else {
            body = const Text('没有更多啦');
          }
          return SizedBox(
            height: 55,
            child: Center(child: body),
          );
        },
      ),
      child: child,
    );
  }
}