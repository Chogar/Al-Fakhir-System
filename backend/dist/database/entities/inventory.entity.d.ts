import { Product } from './product.entity';
export declare class InventoryItem {
    id: string;
    label: string;
    product: Product;
    quantity: string;
    minThreshold: string;
    expiresAt: Date;
    unit: string;
    createdAt: Date;
    updatedAt: Date;
}
