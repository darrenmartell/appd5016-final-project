import {
  IsOptional,
  IsString,
  IsNumber,
  IsInt,
  IsArray,
  Length,
  ArrayUnique,
  IsPositive,
  Max,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { PartialType } from '@nestjs/mapped-types';
import { RatingsDto, EpisodeDto } from './series-base.dto';

export class PatchRatingsDto extends PartialType(RatingsDto) {}
export class PatchEpisodeDto extends PartialType(EpisodeDto) {}

export class PatchSeriesDto {
  @IsOptional()
  @IsString()
  @Length(1, 50)
  title?: string;

  @IsOptional()
  @IsString()
  @Length(1, 500)
  plot_summary?: string;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  @Max(999)
  runtime_minutes?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  cast?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  directors?: string[];

  @IsOptional()
  @IsInt()
  @IsPositive()
  @Max(9999)
  released_year?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  genres?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  countries?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  languages?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  producers?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @Length(1, 50, { each: true })
  @ArrayUnique()
  production_companies?: string[];

  @IsOptional()
  @ValidateNested()
  @Type(() => PatchRatingsDto)
  ratings?: PatchRatingsDto;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PatchEpisodeDto)
  episodes?: PatchEpisodeDto[];
}
