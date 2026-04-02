import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type SeriesDocument = HydratedDocument<Series>;

const hasUniqueItems = (items: string[]) =>
  // Checks if an array of the items is the same length as a set of the same items.
  // If so, then all items are unique.
  Array.isArray(items) && new Set(items).size === items.length;

const hasValidStringItems = (items: string[]) =>
  Array.isArray(items) &&
  items.every(
    (item) => typeof item === 'string' && item.length >= 1 && item.length <= 50,
  );

const isPositiveNumber = (value: number) =>
  typeof value === 'number' && value > 0;

@Schema({ _id: false, strict: true })
class Ratings {
  @Prop({
    type: Number,
    required: true,
    min: 0,
    max: 10,
    validate: { validator: isPositiveNumber },
  })
  imdb: number;

  @Prop({
    type: Number,
    required: true,
    min: 1,
    max: 100,
    validate: { validator: Number.isInteger },
  })
  rotten_tomatoes: number;

  @Prop({
    type: Number,
    required: true,
    min: 1,
    max: 100,
    validate: { validator: Number.isInteger },
  })
  metacritic: number;

  @Prop({
    type: Number,
    required: true,
    min: 0,
    max: 10,
    validate: { validator: isPositiveNumber },
  })
  user_average: number;
}

@Schema({ _id: false, strict: true })
export class Episode {
  @Prop({ type: Number, required: true, min: 1 })
  episode_number: number;

  @Prop({ type: String, required: true, minlength: 1, maxlength: 50 })
  episode_title: string;

  @Prop({ type: Number, required: true, min: 1 })
  runtime_minutes: number;
}

@Schema({ strict: true })
export class Series {
  @Prop({ type: String, required: true, minlength: 1, maxlength: 50 })
  title: string;

  @Prop({ type: String, required: true, minlength: 1, maxlength: 500 })
  plot_summary: string;

  @Prop({ type: Number, required: true, min: 1, max: 999 })
  runtime_minutes: number;

  @Prop({
    type: [String],
    required: true,
    validate: [
      { validator: hasValidStringItems },
      { validator: hasUniqueItems },
    ],
  })
  cast: string[];

  @Prop({
    type: [String],
    required: true,
    validate: [
      { validator: hasValidStringItems },
      { validator: hasUniqueItems },
    ],
  })
  directors: string[];

  // Hides released_date
  @Prop({ type: String, select: false })
  released_date: string;

  @Prop({ type: Number, required: true, min: 1, max: 9999 })
  released_year: number;

  @Prop({
    type: [String],
    required: true,
    validate: [
      { validator: hasValidStringItems },
      { validator: hasUniqueItems },
    ],
  })
  genres: string[];

  @Prop({
    type: [String],
    required: true,
    validate: [
      { validator: hasValidStringItems },
      { validator: hasUniqueItems },
    ],
  })
  countries: string[];

  @Prop({
    type: [String],
    required: true,
    validate: [
      { validator: hasValidStringItems },
      { validator: hasUniqueItems },
    ],
  })
  languages: string[];

  @Prop({
    type: [String],
    required: true,
    validate: [
      { validator: hasValidStringItems },
      { validator: hasUniqueItems },
    ],
  })
  producers: string[];

  @Prop({
    type: [String],
    required: true,
    validate: [
      { validator: hasValidStringItems },
      { validator: hasUniqueItems },
    ],
  })
  production_companies: string[];

  @Prop({ type: Ratings, required: true })
  ratings: Ratings;

  @Prop({ type: [Episode], required: true })
  episodes: Episode[];
}

export const SeriesSchema = SchemaFactory.createForClass(Series);
