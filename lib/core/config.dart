/// App-wide configuration.
///
/// Override the API base URL at build time, e.g. for a staging server:
///   flutter run --dart-define=API_BASE_URL=https://staging.ekor.tj/api
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ekor.tj/api',
  );

  static const supportPhone = '+992446001010';
  static const supportPhoneDisplay = '+992 44 600 10 10';
}
