import { Category } from './category.entity';
import { InventoryItem } from './inventory.entity';
import { OrderItem } from './order-item.entity';
export declare class Product {
    id: string;
    category: Category;
    name: string;
    nameAr: string | null;
    price: string;
    imageUrl: string;
    description: string;
    isAvailable: boolean;
    stockQuantity: number | null;
    stockAlertThreshold: number;
    orderLines: OrderItem[];
    inventoryRows: InventoryItem[];
    createdAt: Date;
    updatedAt: Date;
}
