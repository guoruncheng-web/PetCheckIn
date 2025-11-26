import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Delete,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { PetsService } from './pets.service';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('pets')
@UseGuards(JwtAuthGuard)
export class PetsController {
  constructor(private readonly petsService: PetsService) {}

  @Post()
  async create(@Request() req, @Body() createPetDto: CreatePetDto) {
    const pet = await this.petsService.create(req.user.userId, createPetDto);
    return {
      code: 201,
      data: pet,
      message: '宠物添加成功',
    };
  }

  @Get('me')
  async findMyPets(@Request() req) {
    const pets = await this.petsService.findMyPets(req.user.userId);
    return {
      code: 200,
      data: pets,
      message: '获取成功',
    };
  }

  @Get(':id')
  async findOne(@Request() req, @Param('id') id: string) {
    const pet = await this.petsService.findOne(id, req.user.userId);
    return {
      code: 200,
      data: pet,
      message: '获取成功',
    };
  }

  @Put(':id')
  async update(
    @Request() req,
    @Param('id') id: string,
    @Body() updatePetDto: UpdatePetDto,
  ) {
    const pet = await this.petsService.update(id, req.user.userId, updatePetDto);
    return {
      code: 200,
      data: pet,
      message: '更新成功',
    };
  }

  @Delete(':id')
  async remove(@Request() req, @Param('id') id: string) {
    await this.petsService.remove(id, req.user.userId);
    return {
      code: 200,
      message: '删除成功',
    };
  }
}
