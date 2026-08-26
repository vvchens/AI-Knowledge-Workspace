/// Centralized build-time environment configuration.
///
/// Pass values with `--dart-define=NAME=value` when running or building the
/// Flutter application. Do not place real credentials directly in source.
abstract final class AppEnvironment {
  static const isDev = bool.fromEnvironment('DEV', defaultValue: false);

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMeasurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: '',
  );
}
