import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../database/prisma.service';
export declare class AuthService {
    private readonly prisma;
    private readonly jwtService;
    private otpStore;
    constructor(prisma: PrismaService, jwtService: JwtService);
    sendOtp(phone: string): Promise<{
        success: boolean;
        message: string;
        code: string | undefined;
    }>;
    verifyOtp(phone: string, code: string): Promise<{
        success: boolean;
        isNewUser: boolean;
    }>;
    register(phone: string, password: string, nickname?: string): Promise<{
        success: boolean;
        token: string;
        user: {
            id: string;
            phone: string;
        };
    }>;
    login(phone: string, password: string): Promise<{
        success: boolean;
        token: string;
        user: {
            id: string;
            phone: string;
        };
    }>;
    private cleanExpiredOtp;
}
