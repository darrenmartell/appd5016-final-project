import {
  Body,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Param,
  UseGuards,
} from '@nestjs/common';
import { Controller } from '@nestjs/common';
import { SeriesService } from './series.service';
import { Series } from './schemas/series.schema';
import { CreateSeriesDto } from './dto/create-series.dto';
import { UpdateSeriesDto } from './dto/update-series.dto';
import { PatchSeriesDto } from './dto/patch-series.dto';
import { IsMongoId } from 'class-validator';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';

// Uses class-validator to validate the ID string
export class validateIdParam {
  @IsMongoId()
  id: string;
}

@Controller('series')
export class SeriesController {
  constructor(private readonly seriesService: SeriesService) {}

  @Get()
  findAll(): Promise<Series[]> {
    return this.seriesService.findAll();
  }

  @Get(':id')
  findById(@Param() params: validateIdParam): Promise<Series | null> {
    return this.seriesService.findById(params.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Body() dto: CreateSeriesDto): Promise<Series | null> {
    return this.seriesService.create(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Put(':id')
  update(
    @Param() params: validateIdParam,
    @Body() dto: UpdateSeriesDto,
  ): Promise<Series | null> {
    return this.seriesService.update(params.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch(':id')
  patch(
    @Param() params: validateIdParam,
    @Body() dto: PatchSeriesDto,
  ): Promise<Series | null> {
    return this.seriesService.patch(params.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  remove(@Param() params: validateIdParam): Promise<Series | null> {
    return this.seriesService.remove(params.id);
  }
}
