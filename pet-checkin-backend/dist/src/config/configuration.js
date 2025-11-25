"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = () => ({
    port: parseInt(process.env.PORT || '3000', 10),
    apiPrefix: process.env.API_PREFIX || 'api',
    database: {
        url: process.env.DATABASE_URL,
    },
    redis: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379', 10),
        password: process.env.REDIS_PASSWORD || '',
    },
    jwt: {
        secret: process.env.JWT_SECRET || 'secret',
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    },
    aliyunSms: {
        accessKeyId: process.env.ALIYUN_SMS_ACCESS_KEY_ID,
        accessKeySecret: process.env.ALIYUN_SMS_ACCESS_KEY_SECRET,
        signName: process.env.ALIYUN_SMS_SIGN_NAME || '宠物打卡',
        templateCode: process.env.ALIYUN_SMS_TEMPLATE_CODE,
        region: process.env.ALIYUN_SMS_REGION || 'cn-hangzhou',
    },
    aliyunOss: {
        accessKeyId: process.env.ALIYUN_OSS_ACCESS_KEY_ID,
        accessKeySecret: process.env.ALIYUN_OSS_ACCESS_KEY_SECRET,
        region: process.env.ALIYUN_OSS_REGION || 'oss-cn-hangzhou',
        bucket: process.env.ALIYUN_OSS_BUCKET || 'pet-checkin',
        endpoint: process.env.ALIYUN_OSS_ENDPOINT,
    },
    otp: {
        expiresIn: parseInt(process.env.OTP_EXPIRES_IN || '60', 10),
        retryLimit: parseInt(process.env.OTP_RETRY_LIMIT || '5', 10),
    },
});
//# sourceMappingURL=configuration.js.map