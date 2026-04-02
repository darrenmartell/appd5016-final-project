import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SeriesService } from './series.service';
import { SeriesController } from './series.controller';
import { Series, SeriesSchema } from './schemas/series.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Series.name, schema: SeriesSchema }]),
  ],
  controllers: [SeriesController],
  providers: [SeriesService],
})
export class SeriesModule {}
