import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';
import { Role } from '../database/entities/role.entity';
import { User } from '../database/entities/user.entity';
import { CreateStaffUserDto } from './dto/create-staff-user.dto';
import { UpdateStaffUserDto } from './dto/update-staff-user.dto';
export declare class UsersService {
    private readonly users;
    private readonly roles;
    private readonly config;
    constructor(users: Repository<User>, roles: Repository<Role>, config: ConfigService);
    private bcryptRounds;
    private normalizeStoredPermissions;
    serializeStaff(u: User): {
        id: string;
        username: string;
        fullName: string | null;
        isActive: boolean;
        role: {
            id: string;
            name: import("../common/enums").RoleName;
        } | null;
        permissions: string[] | null;
        effectivePermissions: ("dashboard.view" | "tables.manage" | "pos.access" | "menu.manage" | "finance.view" | "users.manage" | "customers.manage" | "reservations.manage")[];
        createdAt: Date;
        updatedAt: Date;
    };
    serializeRole(r: Role): {
        id: string;
        name: import("../common/enums").RoleName;
    };
    findAllStaffSerialized(): Promise<{
        id: string;
        username: string;
        fullName: string | null;
        isActive: boolean;
        role: {
            id: string;
            name: import("../common/enums").RoleName;
        } | null;
        permissions: string[] | null;
        effectivePermissions: ("dashboard.view" | "tables.manage" | "pos.access" | "menu.manage" | "finance.view" | "users.manage" | "customers.manage" | "reservations.manage")[];
        createdAt: Date;
        updatedAt: Date;
    }[]>;
    listRolesSerialized(): Promise<{
        id: string;
        name: import("../common/enums").RoleName;
    }[]>;
    findOneStaffSerialized(id: string): Promise<{
        id: string;
        username: string;
        fullName: string | null;
        isActive: boolean;
        role: {
            id: string;
            name: import("../common/enums").RoleName;
        } | null;
        permissions: string[] | null;
        effectivePermissions: ("dashboard.view" | "tables.manage" | "pos.access" | "menu.manage" | "finance.view" | "users.manage" | "customers.manage" | "reservations.manage")[];
        createdAt: Date;
        updatedAt: Date;
    }>;
    createStaff(dto: CreateStaffUserDto): Promise<{
        id: string;
        username: string;
        fullName: string | null;
        isActive: boolean;
        role: {
            id: string;
            name: import("../common/enums").RoleName;
        } | null;
        permissions: string[] | null;
        effectivePermissions: ("dashboard.view" | "tables.manage" | "pos.access" | "menu.manage" | "finance.view" | "users.manage" | "customers.manage" | "reservations.manage")[];
        createdAt: Date;
        updatedAt: Date;
    }>;
    updateStaff(id: string, dto: UpdateStaffUserDto, actorId: string): Promise<{
        id: string;
        username: string;
        fullName: string | null;
        isActive: boolean;
        role: {
            id: string;
            name: import("../common/enums").RoleName;
        } | null;
        permissions: string[] | null;
        effectivePermissions: ("dashboard.view" | "tables.manage" | "pos.access" | "menu.manage" | "finance.view" | "users.manage" | "customers.manage" | "reservations.manage")[];
        createdAt: Date;
        updatedAt: Date;
    }>;
    deactivateStaff(id: string, actorId: string): Promise<{
        id: string;
        username: string;
        fullName: string | null;
        isActive: boolean;
        role: {
            id: string;
            name: import("../common/enums").RoleName;
        } | null;
        permissions: string[] | null;
        effectivePermissions: ("dashboard.view" | "tables.manage" | "pos.access" | "menu.manage" | "finance.view" | "users.manage" | "customers.manage" | "reservations.manage")[];
        createdAt: Date;
        updatedAt: Date;
    }>;
    findByUsernameWithSecret(username: string): Promise<User | null>;
    findById(id: string): Promise<User | null>;
}
