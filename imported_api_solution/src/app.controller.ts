import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

// This demonstrates dependency injection of AppService into AppController
// to provide a simple health check endpoint at GET /

@Controller() // Marks this class as a NestJS controller that can handle incoming HTTP requests
export class AppController {
  constructor(private readonly appService: AppService) {} // The AppService is injected into the controller via the constructor

  @Get('/')
  healthCheck() {
    return { status: this.appService.getStatus() };
  }
}
