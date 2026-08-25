import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
      const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
      const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
      const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
      const messagingSenderId =
          String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
      const appId = String.fromEnvironment('FIREBASE_APP_ID');
      const measurementId = String.fromEnvironment(
        'FIREBASE_MEASUREMENT_ID',
        defaultValue: '',
      );

      final missingValues = <String>[
        if (apiKey.isEmpty) 'FIREBASE_API_KEY',
        if (authDomain.isEmpty) 'FIREBASE_AUTH_DOMAIN',
        if (projectId.isEmpty) 'FIREBASE_PROJECT_ID',
        if (storageBucket.isEmpty) 'FIREBASE_STORAGE_BUCKET',
        if (messagingSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
        if (appId.isEmpty) 'FIREBASE_APP_ID',
      ];

      if (missingValues.isNotEmpty) {
        throw StateError(
          'Missing Firebase Web config values: ${missingValues.join(', ')}. '
          'Pass them with --dart-define=NAME=value during flutter run/build.',
        );
      }

      return FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain,
        storageBucket: storageBucket,
        measurementId: measurementId.isEmpty ? null : measurementId,
      );
    }

    throw StateError(
      'This project is configured for Firebase Web. '
      'For Android/iOS, run `flutterfire configure` to regenerate firebase_options.dart '
      'with platform-specific values.',
    );
  }
}
