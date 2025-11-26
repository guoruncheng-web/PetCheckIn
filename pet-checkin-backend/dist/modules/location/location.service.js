"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var LocationService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.LocationService = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = __importDefault(require("axios"));
let LocationService = LocationService_1 = class LocationService {
    logger = new common_1.Logger(LocationService_1.name);
    async getCityByIp(ip) {
        try {
            if (!ip ||
                ip === '::1' ||
                ip === '127.0.0.1' ||
                ip.includes('::ffff:127.0.0.1') ||
                ip.startsWith('::ffff:192.168.') ||
                ip.startsWith('::ffff:10.') ||
                ip.startsWith('::ffff:172.') ||
                ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                ip.startsWith('172.')) {
                this.logger.debug(`Local IP detected: ${ip}, using default location`);
                return {
                    cityCode: '110000',
                    cityName: '北京市',
                    province: '北京',
                    country: '中国',
                };
            }
            const response = await axios_1.default.get(`http://ip-api.com/json/${ip}?lang=zh-CN&fields=status,country,regionName,city`, {
                timeout: 5000,
            });
            if (response.data.status !== 'success') {
                this.logger.warn(`IP location failed: ${JSON.stringify(response.data)}`);
                return this.getDefaultLocation();
            }
            const { country, regionName, city } = response.data;
            if (country !== '中国') {
                this.logger.warn(`Non-China IP: ${ip}, country: ${country}`);
                return null;
            }
            const cityCode = this.getCityCode(city, regionName);
            const cityName = city || regionName || '未知城市';
            this.logger.log(`IP ${ip} located to: ${cityName} (${cityCode}), province: ${regionName}`);
            return {
                cityCode,
                cityName,
                province: regionName,
                country,
            };
        }
        catch (error) {
            this.logger.error(`Failed to get location for IP ${ip}: ${error.message}`);
            return this.getDefaultLocation();
        }
    }
    getClientIp(request) {
        const xForwardedFor = request.headers['x-forwarded-for'];
        if (xForwardedFor) {
            const ips = xForwardedFor.split(',');
            return ips[0].trim();
        }
        const xRealIp = request.headers['x-real-ip'];
        if (xRealIp) {
            return xRealIp;
        }
        return request.ip || request.connection?.remoteAddress || '';
    }
    getDefaultLocation() {
        return {
            cityCode: '110000',
            cityName: '北京市',
            province: '北京',
            country: '中国',
        };
    }
    getCityCode(city, province) {
        const cityMap = {
            北京: '110000',
            天津: '120000',
            上海: '310000',
            重庆: '500000',
            广州: '440100',
            深圳: '440300',
            珠海: '440400',
            佛山: '440600',
            惠州: '441300',
            东莞: '441900',
            中山: '442000',
            杭州: '330100',
            宁波: '330200',
            温州: '330300',
            绍兴: '330500',
            南京: '320100',
            无锡: '320200',
            苏州: '320500',
            南通: '320600',
            成都: '510100',
            武汉: '420100',
            西安: '610100',
            长沙: '430100',
            福州: '350100',
            厦门: '350200',
            合肥: '340100',
            郑州: '410100',
            济南: '370100',
            青岛: '370200',
            沈阳: '210100',
            大连: '210200',
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
        for (const [name, code] of Object.entries(cityMap)) {
            if (city?.includes(name) || province?.includes(name)) {
                return code;
            }
        }
        return '000000';
    }
};
exports.LocationService = LocationService;
exports.LocationService = LocationService = LocationService_1 = __decorate([
    (0, common_1.Injectable)()
], LocationService);
//# sourceMappingURL=location.service.js.map