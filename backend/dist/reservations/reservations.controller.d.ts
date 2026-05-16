import { CreateReservationDto } from './dto/create-reservation.dto';
import { FilterReservationsDto } from './dto/filter-reservations.dto';
import { UpdateReservationDto } from './dto/update-reservation.dto';
import { ReservationsService } from './reservations.service';
export declare class ReservationsController {
    private readonly reservations;
    constructor(reservations: ReservationsService);
    list(query: FilterReservationsDto): Promise<import("../database/entities/reservation.entity").Reservation[]>;
    getOne(id: string): Promise<import("../database/entities/reservation.entity").Reservation>;
    create(dto: CreateReservationDto): Promise<import("../database/entities/reservation.entity").Reservation>;
    update(id: string, dto: UpdateReservationDto): Promise<import("../database/entities/reservation.entity").Reservation>;
}
