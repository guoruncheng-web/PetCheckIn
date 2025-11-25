import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../database/prisma.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  // 内存存储验证码（生产环境应使用 Redis）
  private otpStore = new Map<string, { code: string; expiresAt: number }>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async sendOtp(phone: string) {
    if (!phone || !phone.match(/^1[3-9]\d{9}$/)) {
      throw new BadRequestException('手机号格式错误');
    }

    // 固定验证码 6666（开发环境）
    const code = '6666';
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5分钟过期

    this.otpStore.set(phone, { code, expiresAt });

    // 清理过期的验证码
    this.cleanExpiredOtp();

    return {
      code: 200,
      data: {
        // 开发环境返回验证码，生产环境删除此行
        code: process.env.NODE_ENV === 'development' ? code : undefined,
      },
      message: '验证码已发送',
    };
  }

  async verifyOtp(phone: string, code: string) {
    const stored = this.otpStore.get(phone);

    if (!stored) {
      throw new BadRequestException('验证码不存在或已过期');
    }

    if (Date.now() > stored.expiresAt) {
      this.otpStore.delete(phone);
      throw new BadRequestException('验证码已过期');
    }

    if (stored.code !== code) {
      throw new BadRequestException('验证码错误');
    }

    // 验证成功，删除验证码
    this.otpStore.delete(phone);

    // 检查用户是否存在
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

  async register(phone: string, password: string, nickname?: string) {
    // 检查用户是否已存在
    const existingUser = await this.prisma.user.findUnique({
      where: { phone },
    });

    if (existingUser) {
      throw new BadRequestException('用户已存在');
    }

    // 创建用户
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await this.prisma.user.create({
      data: {
        phone,
        password: hashedPassword,
      },
    });

    // 创建用户资料
    const defaultNickname = nickname || `宠友${phone.slice(-4)}`;
    await this.prisma.profile.create({
      data: {
        userId: user.id,
        nickname: defaultNickname,
      },
    });

    // 生成 JWT Token
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

  async login(phone: string, password: string) {
    const user = await this.prisma.user.findUnique({
      where: { phone },
      include: { profile: true },
    });

    if (!user || !user.password) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('手机号或密码错误');
    }

    // 如果用户没有资料，创建默认资料
    if (!user.profile) {
      const defaultNickname = `宠友${phone.slice(-4)}`;
      await this.prisma.profile.create({
        data: {
          userId: user.id,
          nickname: defaultNickname,
        },
      });
    }

    // 生成 JWT Token
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

  async resetPassword(phone: string, password: string) {
    // 检查用户是否存在
    const user = await this.prisma.user.findUnique({
      where: { phone },
    });

    if (!user) {
      throw new BadRequestException('用户不存在');
    }

    // 更新密码
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

  private cleanExpiredOtp() {
    const now = Date.now();
    for (const [phone, data] of this.otpStore.entries()) {
      if (now > data.expiresAt) {
        this.otpStore.delete(phone);
      }
    }
  }
}
