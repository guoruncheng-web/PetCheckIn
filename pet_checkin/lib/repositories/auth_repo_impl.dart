import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'auth_repo.dart';

/// Supabase 认证仓库实现
class AuthRepoImpl implements AuthRepo {
  final SupabaseClient _client;

  AuthRepoImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> sendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
      shouldCreateUser: true, // 允许注册
    );
  }

  @override
  Future<Profile> verifyOtp(String phone, String token) async {
    final res = await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    final user = res.user!;

    // 检查 profiles 表是否已存在
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      // 首次注册，插入空资料
      await _client.from('profiles').insert({
        'id': user.id,
        'nickname': '宠友', // 默认昵称
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // 重新拉取完整资料
    final profileData = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return Profile.fromJson(profileData);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Profile? currentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    // TODO: 缓存到内存，后续优化
    return null;
  }

  @override
  bool isNewUser() {
    // TODO: 根据 profiles 字段判断是否需要补全
    return false;
  }

  @override
  Stream<Profile?> authStateChanges() async* {
    await for (final state in _client.auth.onAuthStateChange) {
      final user = state.session?.user;
      if (user == null) {
        yield null;
        continue;
      }
      // 拉取完整资料
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      yield Profile.fromJson(data);
    }
  }
}