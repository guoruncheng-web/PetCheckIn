"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const app_module_1 = require("./app.module");
const http_exception_filter_1 = require("./common/filters/http-exception.filter");
const transform_interceptor_1 = require("./common/interceptors/transform.interceptor");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule, {
        logger: ['error', 'warn', 'log', 'debug', 'verbose'],
    });
    const configService = app.get(config_1.ConfigService);
    const port = configService.get('port');
    const apiPrefix = configService.get('apiPrefix');
    const logger = new common_1.Logger('HTTP');
    app.use((req, res, next) => {
        const { method, originalUrl, headers } = req;
        logger.log(`📨 ${method} ${originalUrl}`);
        logger.debug(`Headers: ${JSON.stringify(headers.authorization ? { authorization: headers.authorization } : {})}`);
        next();
    });
    app.setGlobalPrefix(apiPrefix);
    app.enableCors();
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
    }));
    app.useGlobalFilters(new http_exception_filter_1.HttpExceptionFilter());
    app.useGlobalInterceptors(new transform_interceptor_1.TransformInterceptor());
    await app.listen(port);
    console.log(`Application is running on: http://localhost:${port}/${apiPrefix}`);
}
bootstrap();
//# sourceMappingURL=main.js.map