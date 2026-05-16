import { Repository } from 'typeorm';
import { Category } from '../database/entities/category.entity';
import { OrderItem } from '../database/entities/order-item.entity';
import { Product } from '../database/entities/product.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
export declare class ProductsService {
    private readonly products;
    private readonly categories;
    private readonly orderItems;
    constructor(products: Repository<Product>, categories: Repository<Category>, orderItems: Repository<OrderItem>);
    findAll(categoryId?: string): Promise<Product[]>;
    findOne(id: string): Promise<Product>;
    create(dto: CreateProductDto): Promise<Product>;
    update(id: string, dto: UpdateProductDto): Promise<Product>;
    remove(id: string): Promise<void>;
    adjustStock(id: string, delta: number, reason?: string): Promise<Product>;
    findLowStock(): Promise<Product[]>;
    consumeStockForOrder(lines: Array<{
        productId: string;
        quantity: number;
    }>): Promise<void>;
    restoreStockForOrder(lines: Array<{
        productId: string;
        quantity: number;
    }>): Promise<void>;
}
