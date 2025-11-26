"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var StorageService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.StorageService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const OSS = require("ali-oss");
const uuid_1 = require("uuid");
let StorageService = StorageService_1 = class StorageService {
    configService;
    logger = new common_1.Logger(StorageService_1.name);
    ossClient;
    constructor(configService) {
        this.configService = configService;
        this.ossClient = new OSS({
            region: this.configService.get('aliyunOss.region'),
            accessKeyId: this.configService.get('aliyunOss.accessKeyId') ||
                this.configService.get('AccessKeyId'),
            accessKeySecret: this.configService.get('aliyunOss.accessKeySecret') ||
                this.configService.get('AccessKeySecret'),
            bucket: this.configService.get('aliyunOss.bucket'),
        });
        this.logger.log('OSS Client initialized');
    }
    async uploadFile(file, folder = 'uploads') {
        try {
            this.validateFile(file);
            const fileName = this.generateFileName(file, folder);
            this.logger.debug(`Uploading file: ${fileName}`);
            const result = await this.ossClient.put(fileName, file.buffer);
            this.logger.log(`File uploaded successfully: ${result.url}`);
            return result.url;
        }
        catch (error) {
            this.logger.error(`Upload failed: ${error.message}`, error.stack);
            throw new common_1.BadRequestException('文件上传失败');
        }
    }
    validateFile(file) {
        const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
        const allowedVideoTypes = ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/mpeg'];
        const isImage = allowedImageTypes.includes(file.mimetype);
        const isVideo = allowedVideoTypes.includes(file.mimetype);
        if (!isImage && !isVideo) {
            throw new common_1.BadRequestException('只支持图片（JPG、PNG、WEBP）或视频（MP4、MOV）格式');
        }
        const maxSize = isVideo ? 50 * 1024 * 1024 : 5 * 1024 * 1024;
        if (file.size > maxSize) {
            const limit = isVideo ? '50MB' : '5MB';
            throw new common_1.BadRequestException(`文件大小不能超过 ${limit}`);
        }
    }
    generateFileName(file, folder) {
        const ext = file.originalname.split('.').pop()?.toLowerCase() || 'jpg';
        const timestamp = Date.now();
        const uuid = (0, uuid_1.v4)().substring(0, 8);
        return `${folder}/${timestamp}-${uuid}.${ext}`;
    }
    async deleteFile(fileUrl) {
        try {
            const fileName = fileUrl.split('.com/')[1];
            if (fileName) {
                await this.ossClient.delete(fileName);
                this.logger.log(`File deleted: ${fileName}`);
            }
        }
        catch (error) {
            this.logger.warn(`Delete failed: ${error.message}`);
        }
    }
    async getSignedUrl(fileName, expiresIn = 3600) {
        try {
            const url = this.ossClient.signatureUrl(fileName, {
                expires: expiresIn,
            });
            return url;
        }
        catch (error) {
            this.logger.error(`Get signed URL failed: ${error.message}`);
            throw new common_1.BadRequestException('生成签名URL失败');
        }
    }
};
exports.StorageService = StorageService;
exports.StorageService = StorageService = StorageService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], StorageService);
//# sourceMappingURL=storage.service.js.map