import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersService } from './users.service';
import { User, UserSchema } from './schemas/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]), // Registers the User model with Mongoose
  ],
  providers: [UsersService], // Registers the UsersService as a provider that can be injected into other classes (e.g., AuthService)
  exports: [UsersService], // Exports the UsersService so it can be used in other modules (e.g., AuthModule)
})
export class UsersModule {}
