import '../../core/permissions.dart';

class StaffRoleDto {
  const StaffRoleDto({required this.id, required this.name});

  final String id;
  final String name;

  factory StaffRoleDto.fromJson(Map<String, dynamic> j) {
    return StaffRoleDto(
      id: j['id'] as String,
      name: j['name'] as String,
    );
  }
}

class StaffUserDto {
  const StaffUserDto({
    required this.id,
    required this.username,
    this.fullName,
    required this.isActive,
    required this.role,
    this.permissions,
    required this.effectivePermissions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String username;
  final String? fullName;
  final bool isActive;
  final StaffRoleDto role;
  /// Null = utiliser les droits par défaut du rôle.
  final List<String>? permissions;
  final List<String> effectivePermissions;
  final String createdAt;
  final String updatedAt;

  bool get usesRoleDefaultPermissions => permissions == null;

  factory StaffUserDto.fromJson(Map<String, dynamic> j) {
    final r = j['role'];
    final rawPerm = j['permissions'];
    List<String>? permissions;
    if (rawPerm == null) {
      permissions = null;
    } else if (rawPerm is List) {
      permissions = rawPerm.map((e) => '$e').toList();
    }

    List<String> effective = [];
    final rawEff = j['effectivePermissions'];
    if (rawEff is List) {
      effective = rawEff.map((e) => '$e').toList();
    } else {
      final rn = (r as Map<String, dynamic>)['name'] as String?;
      effective = List<String>.from(kRoleDefaultPermissions[rn] ?? const []);
    }

    return StaffUserDto(
      id: j['id'] as String,
      username: j['username'] as String,
      fullName: j['fullName'] as String?,
      isActive: j['isActive'] as bool? ?? true,
      role: StaffRoleDto.fromJson(r as Map<String, dynamic>),
      permissions: permissions,
      effectivePermissions: effective,
      createdAt: j['createdAt']?.toString() ?? '',
      updatedAt: j['updatedAt']?.toString() ?? '',
    );
  }

  String get displaySubtitle {
    final fn = fullName?.trim();
    final bits = <String>[role.name];
    if (fn != null && fn.isNotEmpty) bits.add(fn);
    bits.add(isActive ? 'Actif' : 'Inactif');
    bits.add(usesRoleDefaultPermissions ? 'Droits du rôle' : 'Droits personnalisés');
    return bits.join(' · ');
  }
}
