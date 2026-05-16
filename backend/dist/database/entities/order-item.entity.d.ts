import { Product } from './product.entity';
import { RestaurantOrder } from './restaurant-order.entity';
export declare class OrderItem {
    id: string;
    order: RestaurantOrder;
    product: Product;
    quantity: number;
    unitPrice: string;
    productNameSnapshot: string;
}
