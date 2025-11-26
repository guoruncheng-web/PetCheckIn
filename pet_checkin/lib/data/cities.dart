/// 中国主要城市数据
/// 使用国家统计局的城市编码（行政区划代码前6位）
class CityData {
  final String code;
  final String name;
  final String province;

  const CityData({
    required this.code,
    required this.name,
    required this.province,
  });
}

/// 中国主要城市列表
const List<CityData> chineseCities = [
  // 直辖市
  CityData(code: '110000', name: '北京市', province: '北京'),
  CityData(code: '120000', name: '天津市', province: '天津'),
  CityData(code: '310000', name: '上海市', province: '上海'),
  CityData(code: '500000', name: '重庆市', province: '重庆'),

  // 广东省
  CityData(code: '440100', name: '广州市', province: '广东'),
  CityData(code: '440300', name: '深圳市', province: '广东'),
  CityData(code: '440400', name: '珠海市', province: '广东'),
  CityData(code: '440600', name: '佛山市', province: '广东'),
  CityData(code: '441300', name: '惠州市', province: '广东'),
  CityData(code: '441900', name: '东莞市', province: '广东'),
  CityData(code: '442000', name: '中山市', province: '广东'),

  // 浙江省
  CityData(code: '330100', name: '杭州市', province: '浙江'),
  CityData(code: '330200', name: '宁波市', province: '浙江'),
  CityData(code: '330300', name: '温州市', province: '浙江'),
  CityData(code: '330500', name: '绍兴市', province: '浙江'),

  // 江苏省
  CityData(code: '320100', name: '南京市', province: '江苏'),
  CityData(code: '320200', name: '无锡市', province: '江苏'),
  CityData(code: '320500', name: '苏州市', province: '江苏'),
  CityData(code: '320600', name: '南通市', province: '江苏'),

  // 四川省
  CityData(code: '510100', name: '成都市', province: '四川'),

  // 湖北省
  CityData(code: '420100', name: '武汉市', province: '湖北'),

  // 陕西省
  CityData(code: '610100', name: '西安市', province: '陕西'),

  // 湖南省
  CityData(code: '430100', name: '长沙市', province: '湖南'),

  // 福建省
  CityData(code: '350100', name: '福州市', province: '福建'),
  CityData(code: '350200', name: '厦门市', province: '福建'),

  // 安徽省
  CityData(code: '340100', name: '合肥市', province: '安徽'),

  // 河南省
  CityData(code: '410100', name: '郑州市', province: '河南'),

  // 山东省
  CityData(code: '370100', name: '济南市', province: '山东'),
  CityData(code: '370200', name: '青岛市', province: '山东'),

  // 辽宁省
  CityData(code: '210100', name: '沈阳市', province: '辽宁'),
  CityData(code: '210200', name: '大连市', province: '辽宁'),

  // 黑龙江省
  CityData(code: '230100', name: '哈尔滨市', province: '黑龙江'),

  // 吉林省
  CityData(code: '220100', name: '长春市', province: '吉林'),

  // 云南省
  CityData(code: '530100', name: '昆明市', province: '云南'),

  // 贵州省
  CityData(code: '520100', name: '贵阳市', province: '贵州'),

  // 甘肃省
  CityData(code: '620100', name: '兰州市', province: '甘肃'),

  // 海南省
  CityData(code: '460100', name: '海口市', province: '海南'),

  // 广西壮族自治区
  CityData(code: '450100', name: '南宁市', province: '广西'),

  // 新疆维吾尔自治区
  CityData(code: '650100', name: '乌鲁木齐市', province: '新疆'),

  // 宁夏回族自治区
  CityData(code: '640100', name: '银川市', province: '宁夏'),

  // 西藏自治区
  CityData(code: '540100', name: '拉萨市', province: '西藏'),

  // 内蒙古自治区
  CityData(code: '150100', name: '呼和浩特市', province: '内蒙古'),
];

/// 按省份分组的城市数据
Map<String, List<CityData>> get citiesByProvince {
  final Map<String, List<CityData>> result = {};
  for (final city in chineseCities) {
    result.putIfAbsent(city.province, () => []).add(city);
  }
  return result;
}
