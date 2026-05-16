import type { Request } from 'express';
import { User } from '../database/entities/user.entity';
import { getPermissionsRegistry } from './app-permissions';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
type AuthedRequest = Request & {
    user: User & {
        permissions: string[];
    };
};
export declare class AuthController {
    private readonly auth;
    constructor(auth: AuthService);
    login(dto: LoginDto): Promise<{
        accessToken: string;
        user: {
            id: string;
            username: string;
            fullName: string | null;
            role: import("../common/enums").RoleName;
            permissions: ("dashboard.view" | "tables.manage" | "pos.access" | "menu.manage" | "finance.view" | "users.manage" | "customers.manage" | "reservations.manage")[];
        };
    }>;
    permissions(): ReturnType<typeof getPermissionsRegistry>;
    me(req: AuthedRequest): {
        id: string;
        username: string;
        fullName: string | null;
        role: import("../common/enums").RoleName;
        permissions: string[];
        permissionsCustom: string[];
    };
}
export {};
