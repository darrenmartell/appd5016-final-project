import { Strategy } from 'passport-local';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';
// import { AuthenticatedUser } from './types/authenticated-user.type';
// import { User } from 'src/users/schemas/user.schema';
// import { UserResponseDto } from 'src/users/dto/user-response.dto';

/**
 * LocalStrategy is called by Passport during login authentication.
 * Flow: POST /auth/login → LocalAuthGuard → LocalStrategy.validate() → AuthController.login()
 * This validate() method runs BEFORE the controller method executes.
 */
@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
  constructor(private authService: AuthService) {
    super({ usernameField: 'email' }); // This overrides the default 'username' field to 'email' for login
  }

  /**
   * Step 3: Passport calls this method when LocalAuthGuard is triggered
   * Validates user credentials by calling AuthService.validateUser()
   * @throws UnauthorizedException if user doesn't exist or password is wrong
   */
  async validate(email: string, password: string): Promise<string> {
    const validatedEmail = await this.authService.validateUser(email, password);
    if (!validatedEmail) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return validatedEmail;
  }
}
