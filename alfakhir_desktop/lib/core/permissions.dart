bool userHasPermission(Map<String, dynamic>? user, String permission) {
  final perms = user?['permissions'];
  if (perms is List) {
    return perms.map((e) => e.toString()).contains(permission);
  }
  return false;
}

bool userCanViewAllOrders(Map<String, dynamic>? user) {
  return userHasPermission(user, 'finance.view');
}

bool userCanViewDashboard(Map<String, dynamic>? user) {
  return userHasPermission(user, 'dashboard.view');
}

bool userCanViewFinance(Map<String, dynamic>? user) {
  return userHasPermission(user, 'finance.view');
}

bool userCanManageUsers(Map<String, dynamic>? user) {
  return userHasPermission(user, 'users.manage');
}
