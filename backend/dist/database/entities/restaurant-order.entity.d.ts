import { OrderServiceType, OrderWorkflowStatus } from '../../common/enums';
import { Customer } from './customer.entity';
import { DiningTable } from './dining-table.entity';
import { OrderItem } from './order-item.entity';
import { Payment } from './payment.entity';
import { User } from './user.entity';
export declare class RestaurantOrder {
    id: string;
    orderNumber: number;
    serviceType: OrderServiceType;
    status: OrderWorkflowStatus;
    diningTable: DiningTable;
    customer: Customer;
    createdBy: User;
    notes: string | null;
    items: OrderItem[];
    payments: Payment[];
    createdAt: Date;
    updatedAt: Date;
}
