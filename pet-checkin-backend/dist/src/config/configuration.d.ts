declare const _default: () => {
    port: number;
    apiPrefix: string;
    database: {
        url: string | undefined;
    };
    redis: {
        host: string;
        port: number;
        password: string;
    };
    jwt: {
        secret: string;
        expiresIn: string;
    };
    aliyunSms: {
        accessKeyId: string | undefined;
        accessKeySecret: string | undefined;
        signName: string;
        templateCode: string | undefined;
        region: string;
    };
    aliyunOss: {
        accessKeyId: string | undefined;
        accessKeySecret: string | undefined;
        region: string;
        bucket: string;
        endpoint: string | undefined;
    };
    otp: {
        expiresIn: number;
        retryLimit: number;
    };
};
export default _default;
