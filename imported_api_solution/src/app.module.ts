import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { MongooseModule } from '@nestjs/mongoose';
import { SeriesModule } from './series/series.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { AuthController } from './auth/auth.controller';
import { UsersController } from './users/users.controller';

// The AppModule is the root module of the application that imports all other modules and registers controllers and providers
@Module({
  imports: [
    SeriesModule,
    // Connects to MongoDB using the URI from environment variables
    MongooseModule.forRoot(process.env.MONGODB_URI || '', {
      dbName: process.env.MONGODB_DB_NAME || '',
    }),
    AuthModule,
    UsersModule,
  ],
  controllers: [AuthController, AppController, UsersController], // Registers the AuthController and AppController to handle incoming HTTP requests
  providers: [AppService], // Registers the AppService as a provider that can be injected into controllers (e.g., AppController)
})
export class AppModule {}
