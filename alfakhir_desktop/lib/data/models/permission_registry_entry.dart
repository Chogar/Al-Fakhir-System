class PermissionRegistryEntry {
  const PermissionRegistryEntry({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;

  factory PermissionRegistryEntry.fromJson(Map<String, dynamic> j) {
    return PermissionRegistryEntry(
      key: j['key'] as String,
      label: j['label'] as String,
    );
  }
}
