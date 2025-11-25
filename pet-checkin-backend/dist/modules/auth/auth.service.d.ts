import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../database/prisma.service';
export declare class AuthService {
    private readonly prisma;
    private readonly jwtService;
    private otpStore;
    constructor(prisma: PrismaService, jwtService: JwtService);
    sendOtp(phone: string): Promise<{
        code: number;
        data: {
            code: string | undefined;
        };
        message: string;
    }>;
    verifyOtp(phone: string, code: string): Promise<{
        code: number;
        data: {
            isNewUser: boolean;
        };
        message: string;
    }>;
    register(phone: string, password: string, nickname?: string): Promise<{
        code: number;
        data: {
            token: string;
            user: {
                id: string;
                phone: string;
            };
        };
        message: string;
    }>;
    login(phone: string, password: string): Promise<{
        code: number;
        data: {
            token: string;
            user: {
                id: string;
                phone: string;
            };
        };
        message: string;
    }>;
    resetPassword(phone: string, password: string): Promise<{
        code: number;
        data: null;
        message: string;
    }>;
    private cleanExpiredOtp;
}
