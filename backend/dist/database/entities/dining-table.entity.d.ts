import { TableCategory, TableStatus } from '../../common/enums';
import { Reservation } from './reservation.entity';
import { RestaurantOrder } from './restaurant-order.entity';
export declare class DiningTable {
    id: string;
    number: number;
    capacity: number;
    status: TableStatus;
    tableType: TableCategory;
    reservations: Reservation[];
    orders: RestaurantOrder[];
    createdAt: Date;
    updatedAt: Date;
}
