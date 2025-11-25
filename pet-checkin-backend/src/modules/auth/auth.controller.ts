import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';
import {
  ValidateParams,
  ValidationRules,
} from '../../common/decorators/validate-params.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('send-otp')
  @ValidateParams([
    { field: 'phone', required: true, ...ValidationRules.phone },
  ])
  sendOtp(@Body('phone') phone: string) {
    return this.authService.sendOtp(phone);
  }

  @Post('verify-otp')
  @ValidateParams([
    { field: 'phone', required: true, ...ValidationRules.phone },
    { field: 'code', required: true, ...ValidationRules.otp },
  ])
  async verifyOtp(@Body('phone') phone: string, @Body('code') code: string) {
    return this.authService.verifyOtp(phone, code);
  }

  @Post('register')
  @ValidateParams([
    { field: 'phone', required: true, ...ValidationRules.phone },
    { field: 'password', required: true, ...ValidationRules.password },
  ])
  async register(
    @Body('phone') phone: string,
    @Body('password') password: string,
    @Body('nickname') nickname?: string,
  ) {
    return this.authService.register(phone, password, nickname);
  }

  @Post('login')
  @ValidateParams([
    { field: 'phone', required: true, ...ValidationRules.phone },
    { field: 'password', required: true },
  ])
  async login(
    @Body('phone') phone: string,
    @Body('password') password: string,
  ) {
    return this.authService.login(phone, password);
  }

  @Post('reset-password')
  @ValidateParams([
    { field: 'phone', required: true, ...ValidationRules.phone },
    { field: 'password', required: true, ...ValidationRules.password },
  ])
  async resetPassword(
    @Body('phone') phone: string,
    @Body('password') password: string,
  ) {
    return this.authService.resetPassword(phone, password);
  }
}
