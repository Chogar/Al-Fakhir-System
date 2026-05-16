import { OrderServiceType } from '../../common/enums';
import { OrderLineInputDto } from './order-line-input.dto';
export declare class CreateOrderDto {
    serviceType: OrderServiceType;
    diningTableId?: string;
    customerId?: string;
    notes?: string;
    items: OrderLineInputDto[];
}
