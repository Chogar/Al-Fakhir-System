import { Product } from './product.entity';
export declare class Category {
    id: string;
    slug: string;
    labelFr: string;
    labelAr: string | null;
    sortOrder: number;
    products: Product[];
    createdAt: Date;
    updatedAt: Date;
}
