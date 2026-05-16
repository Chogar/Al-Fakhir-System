import { Repository } from 'typeorm';
import { DiningTable } from '../database/entities/dining-table.entity';
import { Reservation } from '../database/entities/reservation.entity';
import { CreateTableDto } from './dto/create-table.dto';
import { UpdateTableDto } from './dto/update-table.dto';
export declare class TablesService {
    private readonly tablesRepo;
    private readonly reservationsRepo;
    constructor(tablesRepo: Repository<DiningTable>, reservationsRepo: Repository<Reservation>);
    findAll(): Promise<DiningTable[]>;
    findOne(id: string): Promise<DiningTable>;
    create(dto: CreateTableDto): Promise<DiningTable>;
    update(id: string, dto: UpdateTableDto): Promise<DiningTable>;
    remove(id: string): Promise<void>;
}
