import { CheckInsService } from './checkins.service';
import { CreateCheckInDto } from './dto/create-checkin.dto';
import { QueryCheckInDto } from './dto/query-checkin.dto';
export declare class CheckInsController {
    private readonly checkInsService;
    constructor(checkInsService: CheckInsService);
    create(req: any, dto: CreateCheckInDto): Promise<{
        code: number;
        message: string;
        data: {
            user: {
                id: string;
                profile: {
                    id: string;
                    avatarUrl: string | null;
                    nickname: string;
                } | null;
            };
            pet: {
                id: string;
                name: string;
                breed: string | null;
                avatarUrl: string | null;
            };
        } & {
            id: string;
            content: string | null;
            imageUrls: string[];
            videoUrl: string | null;
            tags: string[];
            address: string | null;
            cityCode: string | null;
            cityName: string | null;
            latitude: number | null;
            longitude: number | null;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
            petId: string;
        };
    }>;
    findAll(dto: QueryCheckInDto): Promise<{
        data: ({
            user: {
                id: string;
                profile: {
                    id: string;
                    avatarUrl: string | null;
                    nickname: string;
                } | null;
            };
            pet: {
                id: string;
                name: string;
                breed: string | null;
                avatarUrl: string | null;
            };
            _count: {
                likes: number;
                comments: number;
            };
        } & {
            id: string;
            content: string | null;
            imageUrls: string[];
            videoUrl: string | null;
            tags: string[];
            address: string | null;
            cityCode: string | null;
            cityName: string | null;
            latitude: number | null;
            longitude: number | null;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
            petId: string;
        })[];
        total: number;
        page: number;
        limit: number;
        totalPages: number;
        code: number;
        message: string;
    }>;
    findMyCheckIns(req: any, page?: number, limit?: number): Promise<{
        data: ({
            pet: {
                id: string;
                name: string;
                breed: string | null;
                avatarUrl: string | null;
            };
            _count: {
                likes: number;
                comments: number;
            };
        } & {
            id: string;
            content: string | null;
            imageUrls: string[];
            videoUrl: string | null;
            tags: string[];
            address: string | null;
            cityCode: string | null;
            cityName: string | null;
            latitude: number | null;
            longitude: number | null;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
            petId: string;
        })[];
        total: number;
        page: number;
        limit: number;
        totalPages: number;
        code: number;
        message: string;
    }>;
    findOne(id: string): Promise<{
        code: number;
        message: string;
        data: {
            user: {
                id: string;
                profile: {
                    id: string;
                    avatarUrl: string | null;
                    nickname: string;
                } | null;
            };
            pet: {
                id: string;
                name: string;
                breed: string | null;
                avatarUrl: string | null;
            };
            _count: {
                likes: number;
                comments: number;
            };
        } & {
            id: string;
            content: string | null;
            imageUrls: string[];
            videoUrl: string | null;
            tags: string[];
            address: string | null;
            cityCode: string | null;
            cityName: string | null;
            latitude: number | null;
            longitude: number | null;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
            petId: string;
        };
    }>;
    remove(id: string, req: any): Promise<{
        message: string;
        code: number;
    }>;
}
