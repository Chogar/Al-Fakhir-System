import { Repository } from 'typeorm';
import { Customer } from '../database/entities/customer.entity';
import { Payment } from '../database/entities/payment.entity';
import { RestaurantOrder } from '../database/entities/restaurant-order.entity';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';
export declare class CustomersService {
    private readonly customers;
    private readonly orders;
    private readonly payments;
    constructor(customers: Repository<Customer>, orders: Repository<RestaurantOrder>, payments: Repository<Payment>);
    findAll(search?: string): Promise<Customer[]>;
    findOne(id: string): Promise<Customer>;
    create(dto: CreateCustomerDto): Promise<Customer>;
    update(id: string, dto: UpdateCustomerDto): Promise<Customer>;
    remove(id: string): Promise<void>;
    getStats(id: string): Promise<{
        totalOrders: number;
        paidOrders: number;
        totalSpentFcfa: string;
        averageBasketFcfa: string;
        lastOrderAt: string | null;
    }>;
    findOrders(id: string, limit?: number): Promise<RestaurantOrder[]>;
}
