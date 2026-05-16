import { RoleName } from '../common/enums';
import type { User } from '../database/entities/user.entity';
export declare const APP_PERMISSION_KEYS: readonly ["dashboard.view", "tables.manage", "pos.access", "menu.manage", "finance.view", "users.manage", "customers.manage", "reservations.manage"];
export type AppPermissionKey = (typeof APP_PERMISSION_KEYS)[number];
export declare const APP_PERMISSION_LABELS_FR: Record<AppPermissionKey, string>;
export type PermissionRegistryEntry = {
    key: AppPermissionKey;
    label: string;
};
export declare function getPermissionsRegistry(): PermissionRegistryEntry[];
export declare const ROLE_DEFAULT_PERMISSIONS: Record<RoleName, readonly AppPermissionKey[]>;
export declare function resolveEffectivePermissions(user: User): AppPermissionKey[];
