"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const prisma_service_1 = require("../database/prisma.service");
const bcrypt = __importStar(require("bcrypt"));
let AuthService = class AuthService {
    prisma;
    jwtService;
    otpStore = new Map();
    constructor(prisma, jwtService) {
        this.prisma = prisma;
        this.jwtService = jwtService;
    }
    async sendOtp(phone) {
        if (!phone || !phone.match(/^1[3-9]\d{9}$/)) {
            throw new common_1.BadRequestException('手机号格式错误');
        }
        const code = '6666';
        const expiresAt = Date.now() + 5 * 60 * 1000;
        this.otpStore.set(phone, { code, expiresAt });
        this.cleanExpiredOtp();
        return {
            code: 200,
            data: {
                code: process.env.NODE_ENV === 'development' ? code : undefined,
            },
            message: '验证码已发送',
        };
    }
    async verifyOtp(phone, code) {
        const stored = this.otpStore.get(phone);
        if (!stored) {
            throw new common_1.BadRequestException('验证码不存在或已过期');
        }
        if (Date.now() > stored.expiresAt) {
            this.otpStore.delete(phone);
            throw new common_1.BadRequestException('验证码已过期');
        }
        if (stored.code !== code) {
            throw new common_1.BadRequestException('验证码错误');
        }
        this.otpStore.delete(phone);
        const user = await this.prisma.user.findUnique({
            where: { phone },
        });
        return {
            code: 200,
            data: {
                isNewUser: !user,
            },
            message: '验证成功',
        };
    }
    async register(phone, password, nickname) {
        const existingUser = await this.prisma.user.findUnique({
            where: { phone },
        });
        if (existingUser) {
            throw new common_1.BadRequestException('用户已存在');
        }
        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await this.prisma.user.create({
            data: {
                phone,
                password: hashedPassword,
            },
        });
        const defaultNickname = nickname || `宠友${phone.slice(-4)}`;
        await this.prisma.profile.create({
            data: {
                userId: user.id,
                nickname: defaultNickname,
            },
        });
        const token = this.jwtService.sign({
            sub: user.id,
            phone: user.phone,
        });
        return {
            code: 200,
            data: {
                token,
                user: {
                    id: user.id,
                    phone: user.phone,
                },
            },
            message: '注册成功',
        };
    }
    async login(phone, password) {
        const user = await this.prisma.user.findUnique({
            where: { phone },
            include: { profile: true },
        });
        if (!user || !user.password) {
            throw new common_1.UnauthorizedException('手机号或密码错误');
        }
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            throw new common_1.UnauthorizedException('手机号或密码错误');
        }
        if (!user.profile) {
            const defaultNickname = `宠友${phone.slice(-4)}`;
            await this.prisma.profile.create({
                data: {
                    userId: user.id,
                    nickname: defaultNickname,
                },
            });
        }
        const token = this.jwtService.sign({
            sub: user.id,
            phone: user.phone,
        });
        return {
            code: 200,
            data: {
                token,
                user: {
                    id: user.id,
                    phone: user.phone,
                },
            },
            message: '登录成功',
        };
    }
    async resetPassword(phone, password) {
        const user = await this.prisma.user.findUnique({
            where: { phone },
        });
        if (!user) {
            throw new common_1.BadRequestException('用户不存在');
        }
        const hashedPassword = await bcrypt.hash(password, 10);
        await this.prisma.user.update({
            where: { phone },
            data: { password: hashedPassword },
        });
        return {
            code: 200,
            data: null,
            message: '密码重置成功',
        };
    }
    cleanExpiredOtp() {
        const now = Date.now();
        for (const [phone, data] of this.otpStore.entries()) {
            if (now > data.expiresAt) {
                this.otpStore.delete(phone);
            }
        }
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        jwt_1.JwtService])
], AuthService);
//# sourceMappingURL=auth.service.js.map