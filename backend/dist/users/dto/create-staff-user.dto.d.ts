import { RoleName } from '../../common/enums';
export declare class CreateStaffUserDto {
    username: string;
    password: string;
    fullName?: string;
    role: RoleName;
    isActive?: boolean;
    permissions?: string[] | null;
}
