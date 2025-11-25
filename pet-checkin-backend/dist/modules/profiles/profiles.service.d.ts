import { PrismaService } from '../database/prisma.service';
export declare class ProfilesService {
    private prisma;
    constructor(prisma: PrismaService);
    getProfile(userId: string): Promise<{
        id: string;
        userId: string;
        nickname: string;
        avatarUrl: string | null;
        bio: string | null;
        phone: string;
        cityCode: string | null;
        cityName: string | null;
        province: string | null;
        isVerified: boolean;
        petsCount: number;
        checkinsCount: number;
        followingCount: number;
        followerCount: number;
        totalLikes: number;
        createdAt: Date;
        updatedAt: Date;
    } | null>;
    updateProfile(userId: string, data: {
        nickname?: string;
        avatarUrl?: string;
        bio?: string;
        cityCode?: string;
        cityName?: string;
    }): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        nickname: string;
        avatarUrl: string | null;
        bio: string | null;
        cityCode: string | null;
        cityName: string | null;
        userId: string;
    }>;
}
