import { PrismaService } from '../database/prisma.service';
import { CreateCheckInDto } from './dto/create-checkin.dto';
import { QueryCheckInDto } from './dto/query-checkin.dto';
export declare class CheckInsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(userId: string, dto: CreateCheckInDto): Promise<{
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
    }>;
    findOne(id: string): Promise<{
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
    }>;
    findMyCheckIns(userId: string, page?: number, limit?: number): Promise<{
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
    }>;
    remove(id: string, userId: string): Promise<{
        message: string;
    }>;
}
