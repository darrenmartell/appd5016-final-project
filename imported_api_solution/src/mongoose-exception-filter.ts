import { ArgumentsHost, Catch, ExceptionFilter } from '@nestjs/common';
import { Response } from 'express';
import mongoose from 'mongoose';

@Catch(mongoose.Error)
export class MongooseExceptionFilter implements ExceptionFilter {
  catch(exception: any, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    if (exception instanceof mongoose.Error.ValidationError) {
      return response.status(400).json({
        statusCode: 400,
        message: exception.message,
      });
    }

    console.error('Unhandled Mongoose error:', exception);

    return response.status(500).json({
      statusCode: 500,
      message: 'Internal server error',
    });
  }
}
