import { AuthService } from './auth.service';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
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
}
