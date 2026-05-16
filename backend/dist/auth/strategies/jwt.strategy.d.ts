import { ConfigService } from '@nestjs/config';
import { Strategy } from 'passport-jwt';
import { AuthService } from '../auth.service';
declare const JwtStrategy_base: new (...args: [opt: import("passport-jwt").StrategyOptionsWithRequest] | [opt: import("passport-jwt").StrategyOptionsWithoutRequest]) => Strategy & {
    validate(...args: any[]): unknown;
};
export declare class JwtStrategy extends JwtStrategy_base {
    private readonly auth;
    constructor(config: ConfigService, auth: AuthService);
    validate(payload: {
        sub: string;
    }): Promise<import("../../database/entities/user.entity").User & {
        permissions: ("dashboard.view" | "tables.manage" | "pos.access" | "menu.manage" | "finance.view" | "users.manage" | "customers.manage" | "reservations.manage")[];
    }>;
}
export {};
