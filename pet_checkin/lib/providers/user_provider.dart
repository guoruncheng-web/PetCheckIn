import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pet_checkin/models/profile.dart';
import 'package:pet_checkin/services/api_service.dart';

/// 用户状态管理
/// 提供全局的用户信息访问和持久化
class UserProvider with ChangeNotifier {
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  static const String _cacheKey = 'cached_profile';

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _profile != null;

  /// 从缓存加载用户信息（启动时调用）
  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final json = jsonDecode(cachedData);
        _profile = Profile(
          id: json['id'],
          userId: json['userId'],
          nickname: json['nickname'],
          avatarUrl: json['avatarUrl'],
          bio: json['bio'],
          phone: json['phone'],
          cityCode: json['cityCode'],
          cityName: json['cityName'],
          province: json['province'],
          isVerified: json['isVerified'] ?? false,
          followingCount: json['followingCount'] ?? 0,
          followerCount: json['followerCount'] ?? 0,
          totalLikes: json['totalLikes'] ?? 0,
          createdAt: DateTime.parse(json['createdAt']),
          updatedAt: DateTime.parse(json['updatedAt']),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load cached profile: $e');
    }
  }

  /// 从服务器刷新用户信息
  Future<void> fetchProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService().getMyProfile();

      if (result['code'] == 200 && result['data'] != null) {
        final data = result['data'];
        _profile = Profile(
          id: data['id'],
          userId: data['userId'],
          nickname: data['nickname'],
          avatarUrl: data['avatarUrl'],
          bio: data['bio'],
          phone: data['phone'],
          cityCode: data['cityCode'],
          cityName: data['cityName'],
          province: data['province'],
          isVerified: data['isVerified'] ?? false,
          followingCount: data['followingCount'] ?? 0,
          followerCount: data['followerCount'] ?? 0,
          totalLikes: data['totalLikes'] ?? 0,
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
        );

        // 保存到缓存
        await _saveToCache(data);
      } else if (result['code'] == 404) {
        // 个人信息不存在，设置特殊错误标记
        _error = 'PROFILE_NOT_FOUND';
      } else {
        _error = result['message'] ?? '加载个人信息失败';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to fetch profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新用户信息（本地和服务器）
  Future<bool> updateProfile({
    String? nickname,
    String? avatarUrl,
    String? bio,
    String? cityCode,
    String? cityName,
  }) async {
    try {
      final result = await ApiService().updateMyProfile(
        nickname: nickname,
        avatarUrl: avatarUrl,
        bio: bio,
        cityCode: cityCode,
        cityName: cityName,
      );

      if (result['code'] == 200) {
        // 刷新用户信息
        await fetchProfile();
        return true;
      } else {
        _error = result['message'] ?? '更新失败';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to update profile: $e');
      return false;
    }
  }

  /// 清除用户信息（退出登录）
  Future<void> clearProfile() async {
    _profile = null;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      debugPrint('Failed to clear cached profile: $e');
    }
  }

  /// 保存到本地缓存
  Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save profile to cache: $e');
    }
  }

  /// 更新头像（快捷方法）
  Future<bool> updateAvatar(String avatarUrl) async {
    return await updateProfile(avatarUrl: avatarUrl);
  }

  /// 更新昵称（快捷方法）
  Future<bool> updateNickname(String nickname) async {
    return await updateProfile(nickname: nickname);
  }
}
