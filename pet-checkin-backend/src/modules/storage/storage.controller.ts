import {
  Controller,
  Post,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  Query,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { StorageService } from './storage.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('storage')
@UseGuards(JwtAuthGuard)
export class StorageController {
  constructor(private readonly storageService: StorageService) {}

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: 50 * 1024 * 1024, // 50MB（支持视频上传）
      },
    }),
  )
  async uploadFile(
    @UploadedFile() file: Express.Multer.File,
    @Query('type') type?: string,
  ) {
    if (!file) {
      throw new BadRequestException('请选择要上传的文件');
    }

    // 根据类型决定存储文件夹
    const folderMap: Record<string, string> = {
      avatar: 'avatars',
      pet_avatar: 'pets/avatars',
      pet_photo: 'pets/photos',
      pet_video: 'pets/videos',
      pet: 'pets',
      checkin: 'checkins',
    };

    const folder = folderMap[type || 'avatar'] || 'uploads';

    const url = await this.storageService.uploadFile(file, folder);

    return {
      code: 200,
      data: {
        url,
      },
      message: '上传成功',
    };
  }
}
