import { PaymentMethod } from '../../common/enums';
import { RestaurantOrder } from './restaurant-order.entity';
import { User } from './user.entity';
export declare class Payment {
    id: string;
    order: RestaurantOrder;
    amount: string;
    method: PaymentMethod;
    reference: string;
    recordedBy: User;
    createdAt: Date;
}
