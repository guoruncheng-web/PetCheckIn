import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alice/alice.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  late final Logger _logger;
  late final Alice _alice;
  String? _token;

  static const String _tokenKey = 'auth_token';

  Alice get alice => _alice;

  Future<void> init() async {
    final baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api',
    );

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 100,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTime,
      ),
    );

    // 初始化 Alice
    _alice = Alice();

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 添加 Alice 拦截器（必须在最前面）
    _dio.interceptors.add(_alice.getDioInterceptor());

    // 添加请求拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        _logger.i('🌐 ${options.method} ${options.path}');
        if (options.data != null) {
          _logger.d('📤 请求数据: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i('✅ ${response.statusCode} ${response.requestOptions.path}');
        _logger.d('📥 响应数据: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        _logger.e(
          '❌ ${error.response?.statusCode} ${error.requestOptions.path}',
          error: error.message,
        );
        if (error.response?.data != null) {
          _logger.e('📥 错误响应: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));

    // 加载已保存的 token
    await _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    if (_token != null) {
      _logger.d('🔑 已加载 Token');
    }
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _logger.d('🔑 Token 已保存');
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _logger.d('🔑 Token 已清除');
  }

  String? get token => _token;
  bool get isLoggedIn => _token != null;

  // Auth APIs
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await _dio.post('/auth/send-otp', data: {'phone': phone});
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final response = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'code': code,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(
    String phone,
    String password, {
    String? nickname,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      if (nickname != null) 'nickname': nickname,
    });

    // 保存 token
    if (response.data['data']?['token'] != null) {
      await saveToken(response.data['data']['token']);
    }

    return response.data;
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });

    // 保存 token
    if (response.data['data']?['token'] != null) {
      await saveToken(response.data['data']['token']);
    }

    return response.data;
  }

  Future<void> logout() async {
    await clearToken();
  }

  // 通用请求方法
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }
}
