import { TableCategory, TableStatus } from '../../common/enums';
export declare class UpdateTableDto {
    number?: number;
    capacity?: number;
    tableType?: TableCategory;
    status?: TableStatus;
}
