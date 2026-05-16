import { OrdersService } from '../orders/orders.service';
import { CustomersService } from './customers.service';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';
export declare class CustomersController {
    private readonly customers;
    private readonly orders;
    constructor(customers: CustomersService, orders: OrdersService);
    list(search?: string): Promise<import("../database/entities/customer.entity").Customer[]>;
    getOne(id: string): Promise<import("../database/entities/customer.entity").Customer>;
    stats(id: string): Promise<{
        totalOrders: number;
        paidOrders: number;
        totalSpentFcfa: string;
        averageBasketFcfa: string;
        lastOrderAt: string | null;
    }>;
    ordersHistory(id: string, limitRaw?: string): Promise<Record<string, unknown>[]>;
    create(dto: CreateCustomerDto): Promise<import("../database/entities/customer.entity").Customer>;
    update(id: string, dto: UpdateCustomerDto): Promise<import("../database/entities/customer.entity").Customer>;
    remove(id: string): Promise<void>;
}
