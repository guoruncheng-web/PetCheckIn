import '../models/models.dart';

/// 认证仓库
abstract class AuthRepo {
  /// 发送手机验证码
  Future<void> sendPhoneOtp(String phone);

  /// 验证验证码并登录/注册
  Future<Profile> verifyOtp(String phone, String token);

  /// 退出登录
  Future<void> signOut();

  /// 当前用户
  Profile? currentUser();

  /// 是否新用户（注册后需补全资料）
  bool isNewUser();

  /// 监听认证状态
  Stream<Profile?> authStateChanges();
}