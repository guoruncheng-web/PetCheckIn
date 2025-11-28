import { Module } from '@nestjs/common';
import { CheckInsController } from './checkins.controller';
import { CheckInsService } from './checkins.service';
import { DatabaseModule } from '../database/database.module';

@Module({
  imports: [DatabaseModule],
  controllers: [CheckInsController],
  providers: [CheckInsService],
  exports: [CheckInsService],
})
export class CheckInsModule {}
