import { ReservationStatus } from '../../common/enums';
export declare class UpdateReservationDto {
    guestName?: string;
    guestPhone?: string;
    reservationAt?: string;
    partySize?: number;
    diningTableId?: string;
    status?: ReservationStatus;
}
