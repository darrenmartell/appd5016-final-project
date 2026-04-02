import {
  Injectable,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { LoginResponseDto } from '../users/dto/login-response.dto';
import { CreateUserDto } from '../users/dto/create-user.dto';
// import { UserResponseDto } from 'src/users/dto/user-response.dto';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  /**
   * Step 3: Core authentication logic called by LocalStrategy
   * Checks if user exists and password matches
   * @returns user's email if valid, null otherwise (for both non-existent user and bad password)
   */
  async validateUser(email: string, pass: string): Promise<string | null> {
    const user = await this.usersService.findOne(email);
    if (user && (await bcrypt.compare(pass, user.password))) {
      return user.email;
    }
    return null;
  }

  async login(email: string): Promise<LoginResponseDto> {
    const user = await this.usersService.findOne(email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const payload = {
      sub: user.email,
      _id: String(user._id),
      firstName: user.firstName,
      lastName: user.lastName,
    };
    return {
      message: 'Login successful',
      access_token: await this.jwtService.signAsync(payload),
      _id: String(user._id),
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
    };
  }

  async register(dto: CreateUserDto): Promise<LoginResponseDto> {
    // Check if user already exists
    const existingUser = await this.usersService.findOne(dto.email);
    if (existingUser) {
      throw new ConflictException('User already exists');
    }

    // Create new user
    const user = await this.usersService.create(dto);

    if (!user) {
      throw new UnauthorizedException('Registration failed');
    }

    // Auto-login: generate JWT token
    const payload = {
      sub: user.email,
      _id: String(user._id),
      firstName: user.firstName,
      lastName: user.lastName,
    };

    return {
      message: 'Registration successful',
      access_token: await this.jwtService.signAsync(payload),
      _id: String(user._id),
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
    };
  }
}
