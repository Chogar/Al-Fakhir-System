import { Role } from './role.entity';
export declare class User {
    id: string;
    username: string;
    passwordHash: string;
    fullName: string | null;
    isActive: boolean;
    role: Role;
    permissions: string[] | null;
    createdAt: Date;
    updatedAt: Date;
}
