import { ReservationStatus } from '../../common/enums';
export declare class FilterReservationsDto {
    status?: ReservationStatus;
    dateFrom?: string;
    dateTo?: string;
}
