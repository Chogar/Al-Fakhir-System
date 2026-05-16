/// URL de base de l’API NestJS (préfixe `/api` inclus).
/// Surcharge : `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api`
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:3000/api',
);
