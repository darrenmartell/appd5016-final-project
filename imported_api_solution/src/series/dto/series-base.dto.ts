import { Type } from 'class-transformer';
import {
  IsObject,
  IsString,
  IsNumber,
  IsInt,
  IsNotEmpty,
  IsArray,
  Length,
  ArrayUnique,
  IsPositive,
  Max,
  ValidateNested,
} from 'class-validator';

export class RatingsDto {
  @IsNumber()
  @IsPositive()
  @Max(10)
  readonly imdb: number;

  @IsInt()
  @IsPositive()
  @Max(100)
  readonly rotten_tomatoes: number;

  @IsInt()
  @IsPositive()
  @Max(100)
  readonly metacritic: number;

  @IsNumber()
  @IsPositive()
  @Max(10)
  readonly user_average: number;
}

export class EpisodeDto {
  @IsNumber()
  @IsPositive()
  @IsNotEmpty()
  readonly episode_number: number;

  @IsString()
  @IsNotEmpty()
  @Length(1, 50)
  readonly episode_title: string;

  @IsNumber()
  @IsPositive()
  @IsNotEmpty()
  readonly runtime_minutes: number;
}

export class SeriesBaseDto {
  @IsString()
  @IsNotEmpty()
  @Length(1, 50)
  readonly title: string;

  @IsString()
  @IsNotEmpty()
  @Length(1, 500)
  readonly plot_summary: string;

  @IsNumber()
  @IsPositive()
  @IsNotEmpty()
  @Max(999)
  readonly runtime_minutes: number;

  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  readonly cast: string[];

  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  readonly directors: string[];

  @IsInt()
  @IsPositive()
  @IsNotEmpty()
  @Max(9999)
  readonly released_year: number;

  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  readonly genres: string[];

  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  readonly countries: string[];

  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  readonly languages: string[];

  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  readonly producers: string[];

  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  readonly production_companies: string[];

  @IsObject()
  @ValidateNested()
  @Type(() => RatingsDto)
  readonly ratings: RatingsDto;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => EpisodeDto)
  readonly episodes: EpisodeDto[];
}
