import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OSS = require('ali-oss');
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly ossClient: OSS;

  constructor(private readonly configService: ConfigService) {
    // 初始化 OSS 客户端
    this.ossClient = new OSS({
      region: this.configService.get('aliyunOss.region'),
      accessKeyId:
        this.configService.get('aliyunOss.accessKeyId') ||
        this.configService.get('AccessKeyId'),
      accessKeySecret:
        this.configService.get('aliyunOss.accessKeySecret') ||
        this.configService.get('AccessKeySecret'),
      bucket: this.configService.get('aliyunOss.bucket'),
    });

    this.logger.log('OSS Client initialized');
  }

  /**
   * 上传文件到 OSS
   * @param file 文件
   * @param folder 文件夹名称（如 avatars, pets, checkins）
   * @returns OSS 文件 URL
   */
  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'uploads',
  ): Promise<string> {
    try {
      // 验证文件
      this.validateFile(file);

      // 生成唯一文件名
      const fileName = this.generateFileName(file, folder);

      this.logger.debug(`Uploading file: ${fileName}`);

      // 上传到 OSS
      const result = await this.ossClient.put(fileName, file.buffer);

      this.logger.log(`File uploaded successfully: ${result.url}`);

      // 返回 URL（使用自定义域名或 OSS 默认域名）
      return result.url;
    } catch (error) {
      this.logger.error(`Upload failed: ${error.message}`, error.stack);
      throw new BadRequestException('文件上传失败');
    }
  }

  /**
   * 验证文件
   */
  private validateFile(file: Express.Multer.File): void {
    // 检查文件类型和大小限制
    const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    const allowedVideoTypes = ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/mpeg'];

    const isImage = allowedImageTypes.includes(file.mimetype);
    const isVideo = allowedVideoTypes.includes(file.mimetype);

    if (!isImage && !isVideo) {
      throw new BadRequestException('只支持图片（JPG、PNG、WEBP）或视频（MP4、MOV）格式');
    }

    // 图片最大 5MB，视频最大 50MB
    const maxSize = isVideo ? 50 * 1024 * 1024 : 5 * 1024 * 1024;
    if (file.size > maxSize) {
      const limit = isVideo ? '50MB' : '5MB';
      throw new BadRequestException(`文件大小不能超过 ${limit}`);
    }
  }

  /**
   * 生成文件名
   */
  private generateFileName(
    file: Express.Multer.File,
    folder: string,
  ): string {
    const ext = file.originalname.split('.').pop()?.toLowerCase() || 'jpg';
    const timestamp = Date.now();
    const uuid = uuidv4().substring(0, 8);
    return `${folder}/${timestamp}-${uuid}.${ext}`;
  }

  /**
   * 删除文件（可选）
   */
  async deleteFile(fileUrl: string): Promise<void> {
    try {
      // 从 URL 中提取文件路径
      const fileName = fileUrl.split('.com/')[1];
      if (fileName) {
        await this.ossClient.delete(fileName);
        this.logger.log(`File deleted: ${fileName}`);
      }
    } catch (error) {
      this.logger.warn(`Delete failed: ${error.message}`);
    }
  }

  /**
   * 生成签名 URL（用于私有 Bucket）
   */
  async getSignedUrl(fileName: string, expiresIn: number = 3600): Promise<string> {
    try {
      const url = this.ossClient.signatureUrl(fileName, {
        expires: expiresIn,
      });
      return url;
    } catch (error) {
      this.logger.error(`Get signed URL failed: ${error.message}`);
      throw new BadRequestException('生成签名URL失败');
    }
  }
}
