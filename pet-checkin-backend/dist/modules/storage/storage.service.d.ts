import { ConfigService } from '@nestjs/config';
export declare class StorageService {
    private readonly configService;
    private readonly logger;
    private readonly ossClient;
    constructor(configService: ConfigService);
    uploadFile(file: Express.Multer.File, folder?: string): Promise<string>;
    private validateFile;
    private generateFileName;
    deleteFile(fileUrl: string): Promise<void>;
    getSignedUrl(fileName: string, expiresIn?: number): Promise<string>;
}
