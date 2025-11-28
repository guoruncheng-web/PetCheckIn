import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { CheckInsService } from './checkins.service';
import { CreateCheckInDto } from './dto/create-checkin.dto';
import { QueryCheckInDto } from './dto/query-checkin.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('checkins')
export class CheckInsController {
  constructor(private readonly checkInsService: CheckInsService) {}

  /**
   * 创建打卡
   * POST /api/checkins
   */
  @Post()
  @UseGuards(JwtAuthGuard)
  async create(@Req() req, @Body() dto: CreateCheckInDto) {
    const checkIn = await this.checkInsService.create(req.user.userId, dto);
    return {
      code: 201,
      message: '打卡成功',
      data: checkIn,
    };
  }

  /**
   * 获取打卡列表（支持同城筛选）
   * GET /api/checkins?cityCode=440100&page=1&limit=20
   */
  @Get()
  async findAll(@Query() dto: QueryCheckInDto) {
    const result = await this.checkInsService.findAll(dto);
    return {
      code: 200,
      message: '获取成功',
      ...result,
    };
  }

  /**
   * 获取我的打卡列表
   * GET /api/checkins/me
   */
  @Get('me')
  @UseGuards(JwtAuthGuard)
  async findMyCheckIns(
    @Req() req,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    const result = await this.checkInsService.findMyCheckIns(
      req.user.userId,
      page,
      limit,
    );
    return {
      code: 200,
      message: '获取成功',
      ...result,
    };
  }

  /**
   * 获取打卡详情
   * GET /api/checkins/:id
   */
  @Get(':id')
  async findOne(@Param('id') id: string) {
    const checkIn = await this.checkInsService.findOne(id);
    return {
      code: 200,
      message: '获取成功',
      data: checkIn,
    };
  }

  /**
   * 删除打卡
   * DELETE /api/checkins/:id
   */
  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  async remove(@Param('id') id: string, @Req() req) {
    const result = await this.checkInsService.remove(id, req.user.userId);
    return {
      code: 200,
      ...result,
    };
  }
}
