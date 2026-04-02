import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { MongooseExceptionFilter } from './mongoose-exception-filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({
    origin: [
      'https://polished-bush-a49d.darren-martell.workers.dev',
      'https://harlan-coben-series.netlify.app',
      'http://localhost:5173',
    ],
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type, Accept, Authorization',
    credentials: true,
  }); // Allow CORS
  // Apply ValidationPipe globally for all incoming requests
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strips properties not declared in the DTO
      forbidNonWhitelisted: true, // Returns 400 if unknown properties are sent
      forbidUnknownValues: true, // Rejects completely unknown/non-class payload types
      transform: true, // Converts plain JSON to DTO class instances automatically
    }),
  );
  // Handles all Mongoose exceptions, including validation exceptions
  app.useGlobalFilters(new MongooseExceptionFilter());

  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
