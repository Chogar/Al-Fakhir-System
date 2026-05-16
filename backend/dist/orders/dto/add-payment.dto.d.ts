import { PaymentMethod } from '../../common/enums';
export declare class AddPaymentDto {
    amount: number;
    method: PaymentMethod;
    reference?: string;
}
