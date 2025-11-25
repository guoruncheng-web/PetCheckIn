import { Controller, Get, Put, Body, UseGuards, Request } from '@nestjs/common';
import { ProfilesService } from './profiles.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('profiles')
@UseGuards(JwtAuthGuard)
export class ProfilesController {
  constructor(private readonly profilesService: ProfilesService) {}

  @Get('me')
  async getMyProfile(@Request() req) {
    const userId = req.user.userId;
    const profile = await this.profilesService.getProfile(userId);

    if (!profile) {
      return {
        code: 404,
        message: '个人信息不存在',
        data: null,
      };
    }

    return {
      code: 200,
      message: '获取个人信息成功',
      data: profile,
    };
  }

  @Put('me')
  async updateMyProfile(@Request() req, @Body() body: {
    nickname?: string;
    avatarUrl?: string;
    bio?: string;
    cityCode?: string;
    cityName?: string;
  }) {
    const userId = req.user.userId;
    const profile = await this.profilesService.updateProfile(userId, body);

    return {
      code: 200,
      message: '更新个人信息成功',
      data: profile,
    };
  }
}
