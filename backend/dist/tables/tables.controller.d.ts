import { TablesService } from './tables.service';
import { CreateTableDto } from './dto/create-table.dto';
import { UpdateTableDto } from './dto/update-table.dto';
export declare class TablesController {
    private readonly tables;
    constructor(tables: TablesService);
    list(): Promise<import("../database/entities/dining-table.entity").DiningTable[]>;
    getOne(id: string): Promise<import("../database/entities/dining-table.entity").DiningTable>;
    create(dto: CreateTableDto): Promise<import("../database/entities/dining-table.entity").DiningTable>;
    update(id: string, dto: UpdateTableDto): Promise<import("../database/entities/dining-table.entity").DiningTable>;
    remove(id: string): Promise<void>;
}
