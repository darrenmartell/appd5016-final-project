import { Injectable } from '@nestjs/common';

// This is a simple service that provides application-wide functionality.
// In this case, it has a method to return the status of the application.
// This service is injected into the AppController to demonstrate dependency injection.
@Injectable() // Marks this class as a provider that can be injected into other classes
export class AppService {
  getStatus(): string {
    return 'ok';
  }
}
