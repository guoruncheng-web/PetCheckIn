import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pet_checkin/models/checkin.dart';
import 'package:pet_checkin/utils/toast.dart';

class SquarePage extends StatefulWidget {
  const SquarePage({super.key});

  @override
  State<SquarePage> createState() => _SquarePageState();
}

class _SquarePageState extends State<SquarePage> {
  final RefreshController _refreshController = RefreshController();
  final List<CheckIn> _checkIns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  Future<void> _loadCheckIns({bool refresh = false}) async {
    try {
      // TODO: 迁移到 NestJS API
      if (mounted) {
        setState(() {
          _loading = false;
        });
        if (refresh) _refreshController.refreshCompleted();
      }
    } catch (e) {
      Toast.error('加载失败：$e');
      if (refresh) _refreshController.refreshFailed();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(CheckIn ci) async {
    try {
      // TODO: 迁移到 NestJS API
      await _loadCheckIns();
    } catch (e) {
      Toast.error('操作失败：$e');
    }
  }

  void _showCommentBottomSheet(CheckIn ci) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16.w,
            right: 16.w,
            top: 16.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '说点什么…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () async {
                      final text = ctrl.text.trim();
                      if (text.isEmpty) return;
                      Navigator.pop(context);
                      try {
                        // TODO: 迁移到 NestJS API
                        // await ApiService().createComment(ci.id, text);
                        Toast.success('评论成功');
                        await _loadCheckIns();
                      } catch (e) {
                        Toast.error('评论失败：$e');
                      }
                    },
                    icon: const Icon(Icons.send, color: Colors.orange),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('萌宠广场'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.location_on_outlined),
            onSelected: (v) {
              _loadCheckIns();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: '全部', child: Text('全部城市')),
              const PopupMenuItem(value: '北京', child: Text('北京')),
              const PopupMenuItem(value: '上海', child: Text('上海')),
              const PopupMenuItem(value: '广州', child: Text('广州')),
              const PopupMenuItem(value: '深圳', child: Text('深圳')),
            ],
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: () => _loadCheckIns(refresh: true),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _checkIns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pets,
                          size: 80.w,
                          color: Colors.orange.shade200,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '暂无动态',
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: _checkIns.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (_, i) {
                      final ci = _checkIns[i];
                      return _CheckInCard(
                        ci: ci,
                        onLike: () => _toggleLike(ci),
                        onComment: () => _showCommentBottomSheet(ci),
                      );
                    },
                  ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final CheckIn ci;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const _CheckInCard({required this.ci, required this.onLike, required this.onComment});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onLike(),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: ci.isLiked ? Icons.favorite : Icons.favorite_border,
            label: ci.isLiked ? '取消' : '点赞',
          ),
          SlidableAction(
            onPressed: (_) => onComment(),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.comment,
            label: '评论',
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: ci.petAvatarUrl.isNotEmpty
                      ? Image.network(
                          ci.petAvatarUrl,
                          width: 40.w,
                          height: 40.w,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 40.w,
                          height: 40.w,
                          color: Colors.orange.shade200,
                          child: Icon(
                            Icons.pets,
                            size: 20.w,
                            color: Colors.white,
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ci.petName,
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        ci.short,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (ci.city != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 12.w, color: Colors.orange),
                        SizedBox(width: 4.w),
                        Text(
                          ci.city!,
                          style: TextStyle(fontSize: 11.sp, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            if (ci.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  ci.imageUrls.first,
                  width: double.infinity,
                  height: 160.h,
                  fit: BoxFit.cover,
                ),
              ),
            if (ci.imageUrls.isNotEmpty) SizedBox(height: 12.h),
            Text(
              '今天又是活力满满的一天！',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    ci.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: ci.isLiked ? Colors.redAccent : Colors.grey,
                    size: 20.w,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 4.w),
                Text(
                  ci.likeCount.toString(),
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                ),
                SizedBox(width: 16.w),
                IconButton(
                  onPressed: onComment,
                  icon: Icon(Icons.comment, size: 20.w, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 4.w),
                Text(
                  ci.commentCount.toString(),
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                ),
              ],
            ),
            if (ci.commentCount > 0) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '查看全部 ${ci.commentCount} 条评论',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}