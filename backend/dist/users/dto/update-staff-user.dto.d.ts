import { RoleName } from '../../common/enums';
export declare class UpdateStaffUserDto {
    password?: string;
    fullName?: string | null;
    role?: RoleName;
    isActive?: boolean;
    permissions?: string[] | null;
}
