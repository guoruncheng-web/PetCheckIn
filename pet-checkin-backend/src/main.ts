import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });

  const configService = app.get(ConfigService);
  const port = configService.get('port');
  const apiPrefix = configService.get('apiPrefix');
  const logger = new Logger('HTTP');

  // 请求日志中间件
  app.use((req, res, next) => {
    const { method, originalUrl, headers } = req;
    logger.log(`📨 ${method} ${originalUrl}`);
    logger.debug(`Headers: ${JSON.stringify(headers.authorization ? { authorization: headers.authorization } : {})}`);
    next();
  });

  // 设置全局前缀
  app.setGlobalPrefix(apiPrefix);

  // 启用 CORS
  app.enableCors();

  // 全局验证管道
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // 全局异常过滤器
  app.useGlobalFilters(new HttpExceptionFilter());

  // 全局响应拦截器
  app.useGlobalInterceptors(new TransformInterceptor());

  await app.listen(port);
  console.log(`Application is running on: http://localhost:${port}/${apiPrefix}`);
}
bootstrap();
