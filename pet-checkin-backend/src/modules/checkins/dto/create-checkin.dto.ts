import { IsNotEmpty, IsString, IsArray, IsOptional, IsNumber, MaxLength, ArrayMaxSize } from 'class-validator';

export class CreateCheckInDto {
  @IsNotEmpty({ message: '宠物ID不能为空' })
  @IsString()
  petId: string;

  @IsOptional()
  @IsString()
  @MaxLength(200, { message: '心情文案最多200字' })
  content?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(9, { message: '最多上传9张图片' })
  @IsString({ each: true })
  imageUrls?: string[];

  @IsOptional()
  @IsString()
  videoUrl?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  cityCode?: string;

  @IsOptional()
  @IsString()
  cityName?: string;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;
}
