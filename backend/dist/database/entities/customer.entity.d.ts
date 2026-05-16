import { Reservation } from './reservation.entity';
import { RestaurantOrder } from './restaurant-order.entity';
export declare class Customer {
    id: string;
    name: string;
    phone: string | null;
    loyaltyPoints: number;
    isVip: boolean;
    discountPercent: string;
    reservations: Reservation[];
    orders: RestaurantOrder[];
    createdAt: Date;
    updatedAt: Date;
}
