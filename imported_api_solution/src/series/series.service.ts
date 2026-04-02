/* eslint-disable prettier/prettier */
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Series, SeriesDocument } from './schemas/series.schema';
import { CreateSeriesDto } from './dto/create-series.dto';
import { UpdateSeriesDto } from './dto/update-series.dto';
import { PatchSeriesDto } from './dto/patch-series.dto';

@Injectable()
export class SeriesService {
  constructor(
    @InjectModel(Series.name) private seriesModel: Model<SeriesDocument>,
  ) {}

  protected ensureFound(doc: Series | null, id: string): Series {
    if (!doc) {
      throw new NotFoundException(`Resource with id ${id} not found`);
    }
    return doc;
  }

  async findAll(): Promise<Series[]> {
    return await this.seriesModel.find().exec();
  }

  async findById(id: string): Promise<Series | null> {
    const doc = await this.seriesModel.findById(id).exec();
    return this.ensureFound(doc, id);
  }

  async create(dto: CreateSeriesDto): Promise<Series> {
    return this.seriesModel.create(dto);
  }

  async update(id: string, dto: UpdateSeriesDto): Promise<Series | null> {
    const doc = await this.seriesModel
      .findOneAndReplace({ _id: id }, dto, {
        new: true, // Return the updated document instead of the original
        runValidators: true, // Ensure the new document adheres to the schema validation rules
      })
      .exec();
    return this.ensureFound(doc, id);
  }

  async patch(id: string, dto: PatchSeriesDto): Promise<Series | null> {
    const doc = await this.seriesModel
      .findByIdAndUpdate(id, { $set: dto }, {
         new: true, // Return the updated document instead of the original
         runValidators: true }) // Ensure the updated document adheres to the schema validation rules
      .exec();
    return this.ensureFound(doc, id);
  }

  async remove(id: string): Promise<Series | null> {
    const doc = await this.seriesModel.findByIdAndDelete(id).exec();
    return this.ensureFound(doc, id);
  }
}
