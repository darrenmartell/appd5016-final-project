import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from './schemas/user.schema';
import { CreateUserDto } from './dto/create-user.dto';
import * as bcrypt from 'bcrypt';
import { UserResponseDto } from './dto/user-response.dto';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  protected ensureFound(
    doc: UserDocument | null,
    userId: string,
  ): UserResponseDto {
    if (!doc) {
      throw new NotFoundException(`User with id ${userId} not found`);
    }
    return {
      _id: doc._id.toString(),
      firstName: doc.firstName,
      lastName: doc.lastName,
      email: doc.email,
    };
  }

  async findAll(): Promise<UserResponseDto[]> {
    const users = await this.userModel.find().exec();

    if (!users || users.length === 0) {
      throw new NotFoundException(`No users found`);
    }

    const sanitizedUsers = users.map((user) => {
      return {
        _id: user._id.toString(),
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
      } as UserResponseDto;
    });

    return sanitizedUsers;
  }

  async findById(id: string): Promise<UserResponseDto | null> {
    const doc = await this.userModel.findById(id).exec();
    return this.ensureFound(doc, id);
  }

  // Used by AuthService for validating login credentials, therefore
  // returns full User document including password
  async findOne(email: string): Promise<UserDocument | null> {
    return await this.userModel.findOne({ email }).exec();
  }

  async create(dto: CreateUserDto): Promise<UserDocument> {
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(dto.password, saltRounds);
    return this.userModel.create({
      ...dto,
      password: hashedPassword,
    });
  }

  async remove(id: string): Promise<UserResponseDto | null> {
    const doc = await this.userModel.findByIdAndDelete(id).exec();
    return this.ensureFound(doc, id);
  }
}
