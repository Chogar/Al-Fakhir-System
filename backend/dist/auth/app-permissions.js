"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ROLE_DEFAULT_PERMISSIONS = exports.APP_PERMISSION_LABELS_FR = exports.APP_PERMISSION_KEYS = void 0;
exports.getPermissionsRegistry = getPermissionsRegistry;
exports.resolveEffectivePermissions = resolveEffectivePermissions;
const enums_1 = require("../common/enums");
exports.APP_PERMISSION_KEYS = [
    'dashboard.view',
    'tables.manage',
    'pos.access',
    'menu.manage',
    'finance.view',
    'users.manage',
    'customers.manage',
    'reservations.manage',
];
exports.APP_PERMISSION_LABELS_FR = {
    'dashboard.view': 'Accueil / tableau de bord',
    'tables.manage': 'Tables & plan',
    'pos.access': 'Caisse & commandes',
    'menu.manage': 'Carte & catégories',
    'finance.view': 'Finances & dépenses',
    'users.manage': 'Gestion des utilisateurs',
    'customers.manage': 'Clients',
    'reservations.manage': 'Réservations',
};
function getPermissionsRegistry() {
    return exports.APP_PERMISSION_KEYS.map((key) => ({
        key,
        label: exports.APP_PERMISSION_LABELS_FR[key],
    }));
}
exports.ROLE_DEFAULT_PERMISSIONS = {
    [enums_1.RoleName.ADMIN]: [...exports.APP_PERMISSION_KEYS],
    [enums_1.RoleName.MANAGER]: [
        'dashboard.view',
        'tables.manage',
        'pos.access',
        'menu.manage',
        'finance.view',
        'customers.manage',
        'reservations.manage',
    ],
    [enums_1.RoleName.RECEPTIONIST]: [
        'dashboard.view',
        'tables.manage',
        'reservations.manage',
        'customers.manage',
    ],
    [enums_1.RoleName.SERVER]: ['dashboard.view', 'tables.manage', 'pos.access'],
    [enums_1.RoleName.CASHIER]: ['dashboard.view', 'pos.access', 'menu.manage'],
};
function resolveEffectivePermissions(user) {
    const roleName = user.role?.name;
    const defaults = roleName != null && roleName in exports.ROLE_DEFAULT_PERMISSIONS
        ? [...exports.ROLE_DEFAULT_PERMISSIONS[roleName]]
        : [];
    const custom = user.permissions;
    if (custom == null || (Array.isArray(custom) && custom.length === 0))
        return defaults;
    const allowed = new Set(exports.APP_PERMISSION_KEYS);
    const seen = new Set();
    const result = [];
    for (const k of custom) {
        if (allowed.has(k) && !seen.has(k)) {
            seen.add(k);
            result.push(k);
        }
    }
    return result;
}
//# sourceMappingURL=app-permissions.js.map