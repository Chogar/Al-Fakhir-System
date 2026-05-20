import 'api_config.dart';

String? productImageUri(String? imageUrl) {
  if (imageUrl == null || imageUrl.trim().isEmpty) return null;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }
  final base = kApiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
  final path = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
  return '$base$path';
}
