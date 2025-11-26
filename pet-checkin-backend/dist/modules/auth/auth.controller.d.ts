import { AuthService } from './auth.service';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    sendOtp(phone: string): {
        code: number;
        data: {
            code: string | undefined;
        };
        message: string;
    };
    verifyOtp(phone: string, code: string): Promise<{
        code: number;
        data: {
            isNewUser: boolean;
        };
        message: string;
    }>;
    register(phone: string, password: string, nickname?: string, cityCode?: string, cityName?: string): Promise<{
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
}
