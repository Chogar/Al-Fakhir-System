import { ConfigService } from '@nestjs/config';
import type { Request } from 'express';
import { CreateProductDto } from './dto/create-product.dto';
import { StockAdjustDto, UpdateProductDto } from './dto/update-product.dto';
import { ProductsService } from './products.service';
export declare class ProductsController {
    private readonly products;
    private readonly config;
    constructor(products: ProductsService, config: ConfigService);
    list(categoryId?: string): Promise<import("../database/entities/product.entity").Product[]>;
    lowStock(): Promise<import("../database/entities/product.entity").Product[]>;
    uploadImage(file: Express.Multer.File, req: Request): {
        url: string;
    };
    getOne(id: string): Promise<import("../database/entities/product.entity").Product>;
    create(dto: CreateProductDto): Promise<import("../database/entities/product.entity").Product>;
    update(id: string, dto: UpdateProductDto): Promise<import("../database/entities/product.entity").Product>;
    stockAdjust(id: string, dto: StockAdjustDto): Promise<import("../database/entities/product.entity").Product>;
    remove(id: string): Promise<void>;
}
