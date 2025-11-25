import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  constructor() {
    super({
      log: [
        { level: 'query', emit: 'event' },
        { level: 'info', emit: 'event' },
        { level: 'warn', emit: 'event' },
        { level: 'error', emit: 'event' },
      ],
    });

    // 监听查询事件并打印详细日志
    this.$on('query' as never, (e: any) => {
      this.logger.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      this.logger.debug(`🔍 SQL Query:`);
      this.logger.debug(`   ${e.query}`);
      this.logger.debug(`📊 Params: ${e.params}`);
      this.logger.debug(`⏱️  Duration: ${e.duration}ms`);
      this.logger.debug(`🎯 Target: ${e.target || 'N/A'}`);
      this.logger.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    });

    // 监听信息日志
    this.$on('info' as never, (e: any) => {
      this.logger.log(`ℹ️  ${e.message}`);
    });

    // 监听警告日志
    this.$on('warn' as never, (e: any) => {
      this.logger.warn(`⚠️  ${e.message}`);
    });

    // 监听错误日志
    this.$on('error' as never, (e: any) => {
      this.logger.error(`❌ ${e.message}`);
    });
  }

  async onModuleInit() {
    await this.$connect();
    this.logger.log('✅ Database connected');
  }

  async onModuleDestroy() {
    await this.$disconnect();
    this.logger.log('🔌 Database disconnected');
  }
}
