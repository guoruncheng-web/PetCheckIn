import {
  Controller,
  Get,
  Put,
  Body,
  UseGuards,
  Request,
  Logger,
} from '@nestjs/common';
import { ProfilesService } from './profiles.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

interface AuthRequest extends Request {
  user: {
    userId: string;
    phone: string;
  };
}

@Controller('profiles')
@UseGuards(JwtAuthGuard)
export class ProfilesController {
  private readonly logger = new Logger(ProfilesController.name);

  constructor(private readonly profilesService: ProfilesService) {}

  @Get('me')
  async getMyProfile(@Request() req: AuthRequest) {
    this.logger.log('🔍 GET /profiles/me called');
    this.logger.debug(`User: ${JSON.stringify(req.user)}`);

    const userId = req.user.userId;
    const profile = await this.profilesService.getProfile(userId);

    this.logger.log(`Profile found: ${!!profile}`);
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
  async updateMyProfile(
    @Request() req: AuthRequest,
    @Body()
    body: {
      nickname?: string;
      avatarUrl?: string;
      bio?: string;
      cityCode?: string;
      cityName?: string;
    },
  ) {
    const userId = req.user.userId;
    const profile = await this.profilesService.updateProfile(userId, body);

    return {
      code: 200,
      message: '更新个人信息成功',
      data: profile,
    };
  }
}
