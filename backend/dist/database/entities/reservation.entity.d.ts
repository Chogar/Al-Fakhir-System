import { ReservationStatus } from '../../common/enums';
import { Customer } from './customer.entity';
import { DiningTable } from './dining-table.entity';
export declare class Reservation {
    id: string;
    guestName: string;
    guestPhone: string;
    customer: Customer;
    reservationAt: Date;
    partySize: number;
    diningTable: DiningTable;
    status: ReservationStatus;
    createdAt: Date;
    updatedAt: Date;
}
