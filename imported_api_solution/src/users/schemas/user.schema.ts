import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type UserDocument = HydratedDocument<User> & { _id: Types.ObjectId };

@Schema({ strict: true })
export class User {
  @Prop({
    type: String,
    required: true,
    unique: true,
    minlength: 5,
    maxlength: 50,
  })
  email: string;

  @Prop({ type: String, required: true, minlength: 1, maxlength: 50 })
  firstName: string;

  @Prop({ type: String, required: true, minlength: 1, maxlength: 50 })
  lastName: string;

  @Prop({ type: String, required: true, minlength: 8, maxlength: 128 })
  password: string;
}

export const UserSchema = SchemaFactory.createForClass(User);
