import type { Request } from 'express';
import type { User } from '../database/entities/user.entity';
import { CreateStaffUserDto } from './dto/create-staff-user.dto';
import { UpdateStaffUserDto } from './dto/update-staff-user.dto';
import { UsersService } from './users.service';
export declare class UsersController {
    private readonly users;
    constructor(users: UsersService);
    findAll(): Promise<{
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
    listRoles(): Promise<{
        id: string;
        name: import("../common/enums").RoleName;
    }[]>;
    findOne(id: string): Promise<{
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
    create(dto: CreateStaffUserDto): Promise<{
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
    update(id: string, dto: UpdateStaffUserDto, req: Request & {
        user: User;
    }): Promise<{
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
    remove(id: string, req: Request & {
        user: User;
    }): Promise<{
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
}
