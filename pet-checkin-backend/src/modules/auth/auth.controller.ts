import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('send-otp')
  async sendOtp(@Body('phone') phone: string) {
    return this.authService.sendOtp(phone);
  }

  @Post('verify-otp')
  async verifyOtp(
    @Body('phone') phone: string,
    @Body('code') code: string,
  ) {
    return this.authService.verifyOtp(phone, code);
  }

  @Post('register')
  async register(
    @Body('phone') phone: string,
    @Body('password') password: string,
    @Body('nickname') nickname?: string,
  ) {
    return this.authService.register(phone, password, nickname);
  }

  @Post('login')
  async login(@Body('phone') phone: string, @Body('password') password: string) {
    return this.authService.login(phone, password);
  }

  @Post('reset-password')
  async resetPassword(
    @Body('phone') phone: string,
    @Body('password') password: string,
  ) {
    return this.authService.resetPassword(phone, password);
  }
}
