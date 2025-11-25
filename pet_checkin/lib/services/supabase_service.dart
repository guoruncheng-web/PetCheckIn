import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_checkin/models/profile.dart';
import 'package:pet_checkin/models/pet.dart';
import 'package:pet_checkin/models/checkin.dart';
import 'package:pet_checkin/models/badge.dart' as pet_badge;
import 'dart:typed_data';

class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  static Future<void> init() async {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://your-project.supabase.co'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'your-anon-key'),
    );
  }

  SupabaseClient get client => Supabase.instance.client;
  String? get currentUserId => client.auth.currentUser?.id;

  static final bool _useAliyun =
      const String.fromEnvironment('SMS_PROVIDER', defaultValue: 'supabase') == 'aliyun';

  final navigatorKey = GlobalKey<NavigatorState>();

  bool get isConfigProvided {
    final url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final key = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    return url.isNotEmpty && key.isNotEmpty && url.startsWith('https://');
  }

  Future<bool> quickConnectivityCheck() async {
    try {
      await client.from('profiles').select().limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Auth
  Future<void> signUpWithPhonePassword({required String phone, required String password}) async {
    try {
      final normalized = _normalizePhone(phone);
      final resp = await client.functions.invoke('admin-signup', body: {'phone': normalized, 'password': password});
      final ok = resp.data is Map && (resp.data['ok'] == true);
      if (!ok) {
        throw Exception((resp.data is Map ? resp.data['error'] : null) ?? '注册失败');
      }
      await client.auth.signInWithPassword(phone: normalized, password: password);
      final nickname = '宠友${phone.replaceAll('+86', '').substring(phone.length - 4)}';
      await createProfile(phone: normalized, nickname: nickname);
    } on FunctionException catch (e) {
      if (e.status == 404) {
        throw Exception('后端函数 admin-signup 未部署');
      }
      rethrow;
    }
  }

  Future<void> signInWithPhonePassword({required String phone, required String password}) async {
    final normalized = _normalizePhone(phone);
    await client.auth.signInWithPassword(phone: normalized, password: password);
  }

  String _normalizePhone(String phone) {
    final p = phone.trim();
    final cn = RegExp(r'^1[3-9]\d{9}$');
    if (cn.hasMatch(p)) return '+86$p';
    if (p.startsWith('+')) return p;
    return '+$p';
  }

  Future<void> sendOtp({required String phone}) async {
    if (_useAliyun) {
      final resp = await client.functions.invoke('aliyun-send-otp', body: {'phone': phone});
      if (resp.data == null) {
        throw Exception('Aliyun send OTP failed');
      }
    } else {
      await client.auth.signInWithOtp(phone: phone);
    }
  }

  Future<bool> verifyOtp({required String phone, required String code}) async {
    if (_useAliyun) {
      final resp = await client.functions.invoke('aliyun-verify-otp', body: {'phone': phone, 'code': code});
      final data = resp.data is Map ? resp.data as Map : {};
      final isNew = (data['is_new'] as bool?) ?? false;
      return isNew;
    } else {
      final res = await client.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);
      final data = await client.from('profiles').select().eq('id', res.user!.id).maybeSingle();
      return data == null;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Profile
  Future<Profile> getProfile(String userId) async {
    final res = await client.from('profiles').select().eq('id', userId).single();
    return Profile.fromJson(res);
  }

  Future<void> createProfile({
    required String phone,
    required String nickname,
    String? avatarUrl,
  }) async {
    final user = client.auth.currentUser!;
    await client.from('profiles').insert({
      'id': user.id,
      'phone': phone,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Pet
  Future<List<Pet>> listMyPets(String userId) async {
    final res = await client.from('pets').select().eq('user_id', userId).order('created_at');
    return res.map((e) => Pet.fromJson(e)).toList();
  }

  // CheckIn
  Future<List<CheckIn>> listTodayCheckIns(String userId) async {
    final start = DateTime.now();
    final end = start.add(const Duration(days: 1));
    final res = await client
        .from('checkins')
        .select('''
          *,
          pet:pets!pet_id(name,avatar_url)
        ''')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .order('created_at', ascending: false);
    return res.map((e) => CheckIn.fromJson(e)).toList();
  }

  Future<List<CheckIn>> listSquareCheckIns({String? city}) async {
    var query = client
        .from('checkins')
        .select('''
          *,
          pet:pets!pet_id(name,avatar_url,user_id),
          user:profiles!user_id(nickname,avatar_url),
          likes(count),
          comments(count)
        ''')
        .order('created_at', ascending: false)
        .limit(50);
    
    final res = await query;
    return res.map((e) => CheckIn.fromJson(e)).toList();
  }

  Future<void> createCheckIn(String petId) async {
    await client.from('checkins').insert({
      'pet_id': petId,
      'user_id': currentUserId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Like
  Future<void> toggleLike({required String checkInId}) async {
    final userId = currentUserId!;
    final exists = await client
        .from('likes')
        .select()
        .eq('check_in_id', checkInId)
        .eq('user_id', userId)
        .maybeSingle();
    if (exists == null) {
      await client.from('likes').insert({
        'check_in_id': checkInId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await client.from('likes').delete().eq('id', exists['id']);
    }
  }

  // Comment
  Future<void> createComment({required String checkInId, required String content}) async {
    await client.from('comments').insert({
      'check_in_id': checkInId,
      'user_id': currentUserId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Badge
  Future<List<pet_badge.Badge>> listMyBadges(String userId) async {
    final res = await client
        .from('badges')
        .select()
        .eq('user_id', userId)
        .order('level', ascending: false);
    return res.map((e) => pet_badge.Badge.fromJson(e)).toList();
  }

  // Storage
  Future<String> uploadAvatar(Uint8List bytes, String fileName) async {
    final path = 'avatars/$fileName';
    await client.storage.from('pets').uploadBinary(path, bytes);
    return path;
  }

  String getAvatarUrl(String path) {
    return client.storage.from('pets').getPublicUrl(path);
  }
}
