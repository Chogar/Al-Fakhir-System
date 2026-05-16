/// Construit l’URL d’une image produit pour [Image.network].
///
/// - Chemins relatifs (`/uploads/...`) : complétés avec l’origine déduite de [apiBaseUrl].
/// - URLs absolues vers `/uploads/...` : réécrites sur la même origine que l’API pour éviter
///   les décalages entre `PUBLIC_URL` (backend) et `--dart-define=API_BASE_URL` (Flutter).
Uri? resolveProductImageUri(String raw, String apiBaseUrl) {
  final t = raw.trim();
  if (t.isEmpty) return null;

  final base = Uri.parse(apiBaseUrl);
  final originAuthority = '${base.scheme}://${base.authority}';

  final parsed = Uri.tryParse(t);
  if (parsed != null && parsed.hasScheme) {
    final path = parsed.path;
    if (path.startsWith('/uploads')) {
      final q = parsed.hasQuery ? '?${parsed.query}' : '';
      return Uri.parse('$originAuthority$path$q');
    }
    return parsed;
  }

  final path = t.startsWith('/') ? t : '/$t';
  return Uri.parse(apiBaseUrl).resolve(path);
}
