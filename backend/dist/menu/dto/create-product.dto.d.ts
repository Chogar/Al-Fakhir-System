export declare class CreateProductDto {
    categoryId: string;
    name: string;
    nameAr?: string;
    price: number;
    imageUrl?: string;
    description?: string;
    isAvailable?: boolean;
    stockQuantity?: number | null;
    stockAlertThreshold?: number;
}
