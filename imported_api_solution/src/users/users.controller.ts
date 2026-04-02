import { Get, Delete, Param, UseGuards } from '@nestjs/common';
import { Controller } from '@nestjs/common';
import { UsersService } from './users.service';
import { IsMongoId } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UserResponseDto } from './dto/user-response.dto';

// Uses class-validator to validate the ID string
export class validateIdParam {
  @IsMongoId()
  id: string;
}

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  findAll(): Promise<UserResponseDto[]> {
    return this.usersService.findAll();
  }

  @Get(':id')
  findById(@Param() params: validateIdParam): Promise<UserResponseDto | null> {
    return this.usersService.findById(params.id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  remove(@Param() params: validateIdParam): Promise<UserResponseDto | null> {
    return this.usersService.remove(params.id);
  }
}
