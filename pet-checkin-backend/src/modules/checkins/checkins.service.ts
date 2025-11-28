import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateCheckInDto } from './dto/create-checkin.dto';
import { QueryCheckInDto } from './dto/query-checkin.dto';

@Injectable()
export class CheckInsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * 创建打卡
   */
  async create(userId: string, dto: CreateCheckInDto) {
    // 验证宠物是否属于当前用户
    const pet = await this.prisma.pet.findUnique({
      where: { id: dto.petId },
    });

    if (!pet) {
      throw new NotFoundException('宠物不存在');
    }

    if (pet.userId !== userId) {
      throw new ForbiddenException('无权操作他人的宠物');
    }

    // 创建打卡记录
    const checkIn = await this.prisma.checkIn.create({
      data: {
        userId,
        petId: dto.petId,
        content: dto.content,
        imageUrls: dto.imageUrls || [],
        videoUrl: dto.videoUrl,
        tags: dto.tags || [],
        address: dto.address,
        cityCode: dto.cityCode,
        cityName: dto.cityName,
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
      include: {
        pet: {
          select: {
            id: true,
            name: true,
            breed: true,
            avatarUrl: true,
          },
        },
        user: {
          select: {
            id: true,
            profile: {
              select: {
                id: true,
                nickname: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
    });

    return checkIn;
  }

  /**
   * 查询打卡列表（支持同城筛选）
   */
  async findAll(dto: QueryCheckInDto) {
    const { cityCode, page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (cityCode) {
      where.cityCode = cityCode;
    }

    const [checkins, total] = await Promise.all([
      this.prisma.checkIn.findMany({
        where,
        skip,
        take: limit,
        orderBy: {
          createdAt: 'desc',
        },
        include: {
          pet: {
            select: {
              id: true,
              name: true,
              breed: true,
              avatarUrl: true,
            },
          },
          user: {
            select: {
              id: true,
              profile: {
                select: {
                  id: true,
                  nickname: true,
                  avatarUrl: true,
                },
              },
            },
          },
          _count: {
            select: {
              likes: true,
              comments: true,
            },
          },
        },
      }),
      this.prisma.checkIn.count({ where }),
    ]);

    return {
      data: checkins,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * 获取单个打卡详情
   */
  async findOne(id: string) {
    const checkIn = await this.prisma.checkIn.findUnique({
      where: { id },
      include: {
        pet: {
          select: {
            id: true,
            name: true,
            breed: true,
            avatarUrl: true,
          },
        },
        user: {
          select: {
            id: true,
            profile: {
              select: {
                id: true,
                nickname: true,
                avatarUrl: true,
              },
            },
          },
        },
        _count: {
          select: {
            likes: true,
            comments: true,
          },
        },
      },
    });

    if (!checkIn) {
      throw new NotFoundException('打卡记录不存在');
    }

    return checkIn;
  }

  /**
   * 获取我的打卡列表
   */
  async findMyCheckIns(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [checkins, total] = await Promise.all([
      this.prisma.checkIn.findMany({
        where: { userId },
        skip,
        take: limit,
        orderBy: {
          createdAt: 'desc',
        },
        include: {
          pet: {
            select: {
              id: true,
              name: true,
              breed: true,
              avatarUrl: true,
            },
          },
          _count: {
            select: {
              likes: true,
              comments: true,
            },
          },
        },
      }),
      this.prisma.checkIn.count({ where: { userId } }),
    ]);

    return {
      data: checkins,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * 删除打卡
   */
  async remove(id: string, userId: string) {
    const checkIn = await this.prisma.checkIn.findUnique({
      where: { id },
    });

    if (!checkIn) {
      throw new NotFoundException('打卡记录不存在');
    }

    if (checkIn.userId !== userId) {
      throw new ForbiddenException('无权删除他人的打卡');
    }

    await this.prisma.checkIn.delete({
      where: { id },
    });

    return { message: '删除成功' };
  }
}
