import { UserResponseDto } from './user-response.dto';

export class LoginResponseDto extends UserResponseDto {
  message: string;
  access_token: string;
}
