import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

export interface LocationInfo {
  cityCode: string;
  cityName: string;
  province: string;
  country: string;
}

@Injectable()
export class LocationService {
  private readonly logger = new Logger(LocationService.name);

  /**
   * 根据IP地址获取城市信息
   * 使用 ip-api.com 免费API（无需密钥）
   * 限制：每分钟45次请求
   */
  async getCityByIp(ip: string): Promise<LocationInfo | null> {
    try {
      // 本地IP返回默认值（北京）
      if (
        !ip ||
        ip === '::1' ||
        ip === '127.0.0.1' ||
        ip.includes('::ffff:127.0.0.1') ||
        ip.startsWith('::ffff:192.168.') ||
        ip.startsWith('::ffff:10.') ||
        ip.startsWith('::ffff:172.') ||
        ip.startsWith('192.168.') ||
        ip.startsWith('10.') ||
        ip.startsWith('172.')
      ) {
        this.logger.debug(`Local IP detected: ${ip}, using default location`);
        return {
          cityCode: '110000',
          cityName: '北京市',
          province: '北京',
          country: '中国',
        };
      }

      // 调用 ip-api.com API（支持中文）
      const response = await axios.get(
        `http://ip-api.com/json/${ip}?lang=zh-CN&fields=status,country,regionName,city`,
        {
          timeout: 5000,
        },
      );

      if (response.data.status !== 'success') {
        this.logger.warn(`IP location failed: ${JSON.stringify(response.data)}`);
        return this.getDefaultLocation();
      }

      const { country, regionName, city } = response.data;

      // 中国IP才处理，否则返回null
      if (country !== '中国') {
        this.logger.warn(`Non-China IP: ${ip}, country: ${country}`);
        return null;
      }

      // 映射城市名称到城市代码
      const cityCode = this.getCityCode(city, regionName);
      const cityName = city || regionName || '未知城市';

      this.logger.log(
        `IP ${ip} located to: ${cityName} (${cityCode}), province: ${regionName}`,
      );

      return {
        cityCode,
        cityName,
        province: regionName,
        country,
      };
    } catch (error) {
      this.logger.error(`Failed to get location for IP ${ip}: ${error.message}`);
      return this.getDefaultLocation();
    }
  }

  /**
   * 获取真实客户端IP
   * 优先从 X-Forwarded-For 或 X-Real-IP 获取
   */
  getClientIp(request: any): string {
    const xForwardedFor = request.headers['x-forwarded-for'];
    if (xForwardedFor) {
      // X-Forwarded-For 可能包含多个IP，取第一个
      const ips = xForwardedFor.split(',');
      return ips[0].trim();
    }

    const xRealIp = request.headers['x-real-ip'];
    if (xRealIp) {
      return xRealIp;
    }

    // 从连接信息获取
    return request.ip || request.connection?.remoteAddress || '';
  }

  /**
   * 返回默认位置（北京）
   */
  private getDefaultLocation(): LocationInfo {
    return {
      cityCode: '110000',
      cityName: '北京市',
      province: '北京',
      country: '中国',
    };
  }

  /**
   * 根据城市名称和省份获取城市代码
   * 这里使用简单映射，实际项目可以使用数据库
   */
  private getCityCode(city: string, province: string): string {
    const cityMap: Record<string, string> = {
      // 直辖市
      北京: '110000',
      天津: '120000',
      上海: '310000',
      重庆: '500000',

      // 广东省
      广州: '440100',
      深圳: '440300',
      珠海: '440400',
      佛山: '440600',
      惠州: '441300',
      东莞: '441900',
      中山: '442000',

      // 浙江省
      杭州: '330100',
      宁波: '330200',
      温州: '330300',
      绍兴: '330500',

      // 江苏省
      南京: '320100',
      无锡: '320200',
      苏州: '320500',
      南通: '320600',

      // 四川省
      成都: '510100',

      // 湖北省
      武汉: '420100',

      // 陕西省
      西安: '610100',

      // 湖南省
      长沙: '430100',

      // 福建省
      福州: '350100',
      厦门: '350200',

      // 安徽省
      合肥: '340100',

      // 河南省
      郑州: '410100',

      // 山东省
      济南: '370100',
      青岛: '370200',

      // 辽宁省
      沈阳: '210100',
      大连: '210200',

      // 其他省会城市
      哈尔滨: '230100',
      长春: '220100',
      昆明: '530100',
      贵阳: '520100',
      兰州: '620100',
      海口: '460100',
      南宁: '450100',
      乌鲁木齐: '650100',
      银川: '640100',
      拉萨: '540100',
      呼和浩特: '150100',
    };

    // 直接匹配城市名
    for (const [name, code] of Object.entries(cityMap)) {
      if (city?.includes(name) || province?.includes(name)) {
        return code;
      }
    }

    // 没有匹配到，返回省份默认代码（取省份名第一个字作为标识）
    return '000000';
  }
}
