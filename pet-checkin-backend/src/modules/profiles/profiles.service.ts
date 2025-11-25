import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class ProfilesService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            phone: true,
          },
        },
      },
    });

    if (!profile) {
      return null;
    }

    // 获取用户统计数据
    const [petsCount, checkinsCount] = await Promise.all([
      this.prisma.pet.count({ where: { userId } }),
      this.prisma.checkIn.count({ where: { userId } }),
    ]);

    // 获取总获赞数（所有打卡的点赞数之和）
    const totalLikes = await this.prisma.like.count({
      where: {
        checkIn: {
          userId,
        },
      },
    });

    return {
      id: profile.id,
      userId: profile.userId,
      nickname: profile.nickname,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      phone: profile.user.phone,
      cityCode: profile.cityCode,
      cityName: profile.cityName || profile.cityCode,
      province: profile.cityName, // 简化处理，cityName 作为 province
      isVerified: false, // TODO: 实现认证逻辑
      petsCount,
      checkinsCount,
      followingCount: 0, // TODO: 关注数
      followerCount: 0, // TODO: 粉丝数
      totalLikes,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    };
  }

  async updateProfile(userId: string, data: {
    nickname?: string;
    avatarUrl?: string;
    bio?: string;
    cityCode?: string;
    cityName?: string;
  }) {
    return this.prisma.profile.update({
      where: { userId },
      data,
    });
  }
}
