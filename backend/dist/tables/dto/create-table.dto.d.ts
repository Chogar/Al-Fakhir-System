import { TableCategory, TableStatus } from '../../common/enums';
export declare class CreateTableDto {
    number: number;
    capacity: number;
    tableType: TableCategory;
    status?: TableStatus;
}
