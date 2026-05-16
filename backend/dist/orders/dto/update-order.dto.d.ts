import { OrderServiceType, OrderWorkflowStatus } from '../../common/enums';
export declare class UpdateOrderDto {
    status?: OrderWorkflowStatus;
    serviceType?: OrderServiceType;
    diningTableId?: string | null;
    customerId?: string | null;
    notes?: string | null;
}
