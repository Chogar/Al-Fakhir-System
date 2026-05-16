export declare class UpdateProductDto {
    categoryId?: string;
    name?: string;
    nameAr?: string;
    price?: number;
    imageUrl?: string;
    description?: string;
    isAvailable?: boolean;
    stockQuantity?: number | null;
    stockAlertThreshold?: number;
}
export declare class StockAdjustDto {
    delta: number;
    reason?: string;
}
