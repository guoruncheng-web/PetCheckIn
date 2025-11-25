import { ProfilesService } from './profiles.service';
interface AuthRequest extends Request {
    user: {
        userId: string;
        phone: string;
    };
}
export declare class ProfilesController {
    private readonly profilesService;
    private readonly logger;
    constructor(profilesService: ProfilesService);
    getMyProfile(req: AuthRequest): Promise<{
        code: number;
        message: string;
        data: null;
    } | {
        code: number;
        message: string;
        data: {
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
        };
    }>;
    updateMyProfile(req: AuthRequest, body: {
        nickname?: string;
        avatarUrl?: string;
        bio?: string;
        cityCode?: string;
        cityName?: string;
    }): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            nickname: string;
            avatarUrl: string | null;
            bio: string | null;
            cityCode: string | null;
            cityName: string | null;
            userId: string;
        };
    }>;
}
export {};
