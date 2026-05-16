import { CategoriesService } from './categories.service';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/create-category.dto';
declare class MergePairDto {
    sourceId: string;
    targetId: string;
}
declare class MergeBulkDto {
    pairs: MergePairDto[];
}
export declare class CategoriesController {
    private readonly categories;
    constructor(categories: CategoriesService);
    list(): Promise<(import("../database/entities/category.entity").Category & {
        productCount: number;
    })[]>;
    duplicates(): Promise<{
        key: string;
        target: import("../database/entities/category.entity").Category & {
            productCount: number;
        };
        sources: Array<import("../database/entities/category.entity").Category & {
            productCount: number;
        }>;
        totalProducts: number;
    }[]>;
    getOne(id: string): Promise<import("../database/entities/category.entity").Category>;
    merge(id: string, targetId: string): Promise<{
        movedCount: number;
        targetId: string;
    }>;
    mergeBulk(dto: MergeBulkDto): Promise<{
        appliedCount: number;
        movedProducts: number;
        errors: Array<{
            sourceId: string;
            targetId: string;
            message: string;
        }>;
    }>;
    create(dto: CreateCategoryDto): Promise<import("../database/entities/category.entity").Category>;
    update(id: string, dto: UpdateCategoryDto): Promise<import("../database/entities/category.entity").Category>;
    remove(id: string): Promise<void>;
}
export {};
