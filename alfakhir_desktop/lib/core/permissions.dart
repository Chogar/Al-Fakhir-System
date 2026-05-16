/// Clés alignées sur `backend/src/auth/app-permissions.ts` et les défauts par rôle.
const List<String> kAppPermissionKeys = [
  'dashboard.view',
  'tables.manage',
  'pos.access',
  'menu.manage',
  'finance.view',
  'users.manage',
  'customers.manage',
  'reservations.manage',
];

final Map<String, String> kPermissionLabelsFr = {
  'dashboard.view': 'Accueil / tableau de bord',
  'tables.manage': 'Tables & plan',
  'pos.access': 'Caisse & commandes',
  'menu.manage': 'Carte & catégories',
  'finance.view': 'Finances & dépenses',
  'users.manage': 'Gestion des utilisateurs',
  'customers.manage': 'Clients',
  'reservations.manage': 'Réservations',
};

final Map<String, List<String>> kRoleDefaultPermissions = {
  'ADMIN': [...kAppPermissionKeys],
  'MANAGER': [
    'dashboard.view',
    'tables.manage',
    'pos.access',
    'menu.manage',
    'finance.view',
    'customers.manage',
    'reservations.manage',
  ],
  'RECEPTIONIST': [
    'dashboard.view',
    'tables.manage',
    'reservations.manage',
    'customers.manage',
  ],
  'SERVER': [
    'dashboard.view',
    'tables.manage',
    'pos.access',
  ],
  'CASHIER': [
    'dashboard.view',
    'pos.access',
    'menu.manage',
  ],
};

/// Sessions anciennes sans champ `permissions` : retomber sur les défauts du rôle.
List<String> effectivePermissionsFromUser(Map<String, dynamic>? user) {
  final raw = user?['permissions'];
  if (raw is List<String>) {
    return List<String>.from(raw);
  }
  if (raw is List) {
    return raw.map((e) => '$e').toList();
  }
  final role = user?['role'] as String?;
  final fb = kRoleDefaultPermissions[role];
  return fb != null ? List<String>.from(fb) : [];
}

bool userHasPermission(Map<String, dynamic>? user, String permission) {
  return effectivePermissionsFromUser(user).contains(permission);
}

/// Gérants / admins : toutes les ventes. Caissiers et serveurs : les leurs uniquement.
bool userCanViewAllOrders(Map<String, dynamic>? user) {
  return userHasPermission(user, 'finance.view');
}
