import { Repository } from 'typeorm';
import { Category } from '../database/entities/category.entity';
import { Product } from '../database/entities/product.entity';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/create-category.dto';
export declare class CategoriesService {
    private readonly categories;
    private readonly products;
    constructor(categories: Repository<Category>, products: Repository<Product>);
    findAll(): Promise<Category[]>;
    findAllWithCounts(): Promise<Array<Category & {
        productCount: number;
    }>>;
    findOne(id: string): Promise<Category>;
    normalizeSlug(raw: string): string;
    create(dto: CreateCategoryDto): Promise<Category>;
    update(id: string, dto: UpdateCategoryDto): Promise<Category>;
    remove(id: string): Promise<void>;
    mergeInto(sourceId: string, targetId: string): Promise<{
        movedCount: number;
        targetId: string;
    }>;
    private normalizeLabelKey;
    findDuplicates(): Promise<Array<{
        key: string;
        target: Category & {
            productCount: number;
        };
        sources: Array<Category & {
            productCount: number;
        }>;
        totalProducts: number;
    }>>;
    mergeBulk(pairs: Array<{
        sourceId: string;
        targetId: string;
    }>): Promise<{
        appliedCount: number;
        movedProducts: number;
        errors: Array<{
            sourceId: string;
            targetId: string;
            message: string;
        }>;
    }>;
}
