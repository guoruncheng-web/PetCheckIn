import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreatePetDto } from './dto/create-pet.dto';

@Injectable()
export class PetsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, createPetDto: CreatePetDto) {
    // 检查用户宠物数量（最多5只）
    const petCount = await this.prisma.pet.count({
      where: { userId },
    });

    if (petCount >= 5) {
      throw new BadRequestException('每个用户最多只能添加5只宠物');
    }

    // 检查图片数量（最多6张）
    if (createPetDto.imageUrls && createPetDto.imageUrls.length > 6) {
      throw new BadRequestException('最多只能上传6张照片');
    }

    // 创建宠物
    const pet = await this.prisma.pet.create({
      data: {
        userId,
        name: createPetDto.name,
        breed: createPetDto.breed,
        gender: createPetDto.gender,
        birthday: createPetDto.birthday ? new Date(createPetDto.birthday) : undefined,
        weight: createPetDto.weight,
        avatarUrl: createPetDto.avatarUrl,
        description: createPetDto.description,
        imageUrls: createPetDto.imageUrls || [],
        videoUrl: createPetDto.videoUrl,
      },
    });

    return pet;
  }

  async findMyPets(userId: string) {
    const pets = await this.prisma.pet.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    return pets;
  }

  async findOne(id: string, userId: string) {
    const pet = await this.prisma.pet.findFirst({
      where: { id, userId },
    });

    if (!pet) {
      throw new NotFoundException('宠物不存在');
    }

    return pet;
  }

  async remove(id: string, userId: string) {
    const pet = await this.findOne(id, userId);

    await this.prisma.pet.delete({
      where: { id: pet.id },
    });

    return { message: '删除成功' };
  }
}
