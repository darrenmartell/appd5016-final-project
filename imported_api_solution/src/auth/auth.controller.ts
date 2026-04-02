// import { Controller, Request, Body, Post, UseGuards } from '@nestjs/common';
import { Controller, Body, Post, UseGuards } from '@nestjs/common';
import { LocalAuthGuard } from './local-auth.guard';
import { AuthService } from './auth.service';
import { LoginResponseDto } from '../users/dto/login-response.dto';
import { LoginDto } from '../users/dto/login.dto';
import { CreateUserDto } from '../users/dto/create-user.dto';
// import { Request as ExpressRequest } from 'express';
// import { AuthenticatedUser } from './types/authenticated-user.type';

@Controller()
export class AuthController {
  constructor(private authService: AuthService) {}

  /**
   * Step 1: User sends POST /auth/login with credentials
   * Step 2: LocalAuthGuard intercepts the request
   * Step 4: If validation passes, this method generates and returns JWT token
   * If validation fails, BadRequestException is thrown before reaching here
   */
  @UseGuards(LocalAuthGuard)
  @Post('auth/login')
  async login(
    @Body() dto: LoginDto,
    // @Request() req: ExpressRequest & { user: AuthenticatedUser },
  ): Promise<LoginResponseDto> {
    return this.authService.login(dto.email);
  }

  @Post('auth/register')
  async register(@Body() dto: CreateUserDto): Promise<LoginResponseDto> {
    return this.authService.register(dto);
  }
}
