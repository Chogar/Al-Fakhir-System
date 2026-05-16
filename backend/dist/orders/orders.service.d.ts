import { Repository } from 'typeorm';
import { Customer } from '../database/entities/customer.entity';
import { DiningTable } from '../database/entities/dining-table.entity';
import { OrderItem } from '../database/entities/order-item.entity';
import { Payment } from '../database/entities/payment.entity';
import { Product } from '../database/entities/product.entity';
import { RestaurantOrder } from '../database/entities/restaurant-order.entity';
import { User } from '../database/entities/user.entity';
import { AddPaymentDto } from './dto/add-payment.dto';
import { CreateOrderDto } from './dto/create-order.dto';
import { ReplaceOrderItemsDto } from './dto/replace-order-items.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
export declare class OrdersService {
    private readonly orders;
    private readonly orderItems;
    private readonly payments;
    private readonly products;
    private readonly tables;
    private readonly customers;
    private readonly users;
    constructor(orders: Repository<RestaurantOrder>, orderItems: Repository<OrderItem>, payments: Repository<Payment>, products: Repository<Product>, tables: Repository<DiningTable>, customers: Repository<Customer>, users: Repository<User>);
    private computeTotals;
    serialize(order: RestaurantOrder): Record<string, unknown>;
    private refreshTableStatus;
    private buildLinesFromInput;
    private applyStockDelta;
    create(dto: CreateOrderDto, createdById?: string): Promise<unknown>;
    findHistory(opts?: {
        from?: string;
        to?: string;
    }): Promise<unknown[]>;
    findAll(opts?: {
        openOnly?: boolean;
        kitchen?: boolean;
    }): Promise<unknown[]>;
    findOneEntity(id: string): Promise<RestaurantOrder>;
    findOne(id: string): Promise<unknown>;
    update(id: string, dto: UpdateOrderDto): Promise<unknown>;
    replaceItems(id: string, dto: ReplaceOrderItemsDto): Promise<unknown>;
    addPayment(id: string, dto: AddPaymentDto, recordedById?: string): Promise<unknown>;
}
