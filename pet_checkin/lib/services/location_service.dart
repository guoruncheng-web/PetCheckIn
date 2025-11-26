import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pet_checkin/data/cities.dart';

class LocationService {
  /// 获取当前位置并转换为城市信息
  /// 返回 Map: {cityCode: String, cityName: String}
  static Future<Map<String, String>?> getCurrentCity() async {
    try {
      // 1. 检查定位权限
      final permission = await _checkPermission();
      if (!permission) {
        print('❌ 定位权限被拒绝');
        return null;
      }

      // 2. 获取当前位置
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      print('📍 GPS位置: ${position.latitude}, ${position.longitude}');

      // 3. 反向地理编码：经纬度 → 城市名
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        print('❌ 无法解析地址');
        return null;
      }

      final placemark = placemarks.first;
      print('🏙️ 地址信息: ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}');

      // 4. 提取城市名
      String? cityName = placemark.locality ?? placemark.administrativeArea;
      if (cityName == null || cityName.isEmpty) {
        print('❌ 无法获取城市名');
        return null;
      }

      // 移除"市"后缀用于匹配
      final cityNameForMatch = cityName.replaceAll('市', '');

      // 5. 在城市列表中查找匹配的城市代码
      String? cityCode;
      for (final city in chineseCities) {
        if (city.name.contains(cityNameForMatch) ||
            cityNameForMatch.contains(city.name.replaceAll('市', ''))) {
          cityCode = city.code;
          cityName = city.name; // 使用标准城市名
          break;
        }
      }

      if (cityCode == null) {
        print('⚠️ 未在城市列表中找到: $cityName，使用默认代码');
        cityCode = '000000';
      }

      print('✅ 定位成功: $cityName ($cityCode)');
      return {
        'cityCode': cityCode,
        'cityName': cityName!,
      };
    } catch (e) {
      print('❌ 获取位置失败: $e');
      return null;
    }
  }

  /// 检查并请求定位权限
  static Future<bool> _checkPermission() async {
    // 检查定位服务是否开启
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ 定位服务未开启');
      return false;
    }

    // 检查权限
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 请求权限
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ 定位权限被永久拒绝');
      return false;
    }

    return true;
  }

  /// 检查定位权限状态（不请求）
  static Future<bool> hasPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// 打开系统设置页面
  static Future<void> openSettings() async {
    await Geolocator.openLocationSettings();
  }
}
