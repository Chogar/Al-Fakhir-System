import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
export declare class AuthService {
    private readonly users;
    private readonly jwt;
    constructor(users: UsersService, jwt: JwtService);
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
    verifyPayload(payload: {
        sub: string;
    }): Promise<import("../database/entities/user.entity").User>;
}
