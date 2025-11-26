import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';

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

  async update(id: string, userId: string, updatePetDto: UpdatePetDto) {
    // 先验证宠物是否存在且属于当前用户
    await this.findOne(id, userId);

    // 检查图片数量（最多6张）
    if (updatePetDto.imageUrls && updatePetDto.imageUrls.length > 6) {
      throw new BadRequestException('最多只能上传6张照片');
    }

    // 更新宠物信息（注意：性别不能修改）
    const pet = await this.prisma.pet.update({
      where: { id },
      data: {
        ...(updatePetDto.name && { name: updatePetDto.name }),
        ...(updatePetDto.breed !== undefined && { breed: updatePetDto.breed }),
        ...(updatePetDto.birthday && { birthday: new Date(updatePetDto.birthday) }),
        ...(updatePetDto.weight !== undefined && { weight: updatePetDto.weight }),
        ...(updatePetDto.avatarUrl !== undefined && { avatarUrl: updatePetDto.avatarUrl }),
        ...(updatePetDto.description !== undefined && { description: updatePetDto.description }),
        ...(updatePetDto.imageUrls !== undefined && { imageUrls: updatePetDto.imageUrls }),
        ...(updatePetDto.videoUrl !== undefined && { videoUrl: updatePetDto.videoUrl }),
      },
    });

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
