import { StorageService } from './storage.service';
export declare class StorageController {
    private readonly storageService;
    constructor(storageService: StorageService);
    uploadFile(file: Express.Multer.File, type?: string): Promise<{
        code: number;
        data: {
            url: string;
        };
        message: string;
    }>;
}
