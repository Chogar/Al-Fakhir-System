import { Repository } from 'typeorm';
import { Customer } from '../database/entities/customer.entity';
import { DiningTable } from '../database/entities/dining-table.entity';
import { Reservation } from '../database/entities/reservation.entity';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { FilterReservationsDto } from './dto/filter-reservations.dto';
import { UpdateReservationDto } from './dto/update-reservation.dto';
export declare class ReservationsService {
    private readonly reservationsRepo;
    private readonly tablesRepo;
    private readonly customersRepo;
    constructor(reservationsRepo: Repository<Reservation>, tablesRepo: Repository<DiningTable>, customersRepo: Repository<Customer>);
    findAll(filters: FilterReservationsDto): Promise<Reservation[]>;
    findOne(id: string): Promise<Reservation>;
    create(dto: CreateReservationDto): Promise<Reservation>;
    update(id: string, dto: UpdateReservationDto): Promise<Reservation>;
}
