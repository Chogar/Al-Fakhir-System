import type { Request } from 'express';
import { User } from '../database/entities/user.entity';
import { AddPaymentDto } from './dto/add-payment.dto';
import { CreateOrderDto } from './dto/create-order.dto';
import { ReplaceOrderItemsDto } from './dto/replace-order-items.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { OrdersService } from './orders.service';
type RequestWithUser = Request & {
    user: User & {
        permissions: string[];
    };
};
export declare class OrdersController {
    private readonly orders;
    constructor(orders: OrdersService);
    list(openOnly?: string, kitchen?: string): Promise<unknown[]>;
    history(from?: string, to?: string): Promise<unknown[]>;
    create(dto: CreateOrderDto, req: RequestWithUser): Promise<unknown>;
    getOne(id: string): Promise<unknown>;
    update(id: string, dto: UpdateOrderDto): Promise<unknown>;
    replaceItems(id: string, dto: ReplaceOrderItemsDto): Promise<unknown>;
    addPayment(id: string, dto: AddPaymentDto, req: RequestWithUser): Promise<unknown>;
}
export {};
