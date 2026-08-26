import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'environment.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      final missingValues = <String>[
        if (AppEnvironment.firebaseApiKey.isEmpty) 'FIREBASE_API_KEY',
        if (AppEnvironment.firebaseAuthDomain.isEmpty) 'FIREBASE_AUTH_DOMAIN',
        if (AppEnvironment.firebaseProjectId.isEmpty) 'FIREBASE_PROJECT_ID',
        if (AppEnvironment.firebaseStorageBucket.isEmpty)
          'FIREBASE_STORAGE_BUCKET',
        if (AppEnvironment.firebaseMessagingSenderId.isEmpty)
          'FIREBASE_MESSAGING_SENDER_ID',
        if (AppEnvironment.firebaseAppId.isEmpty) 'FIREBASE_APP_ID',
      ];

      if (missingValues.isNotEmpty) {
        throw StateError(
          'Missing Firebase Web config values: ${missingValues.join(', ')}. '
          'Pass them with --dart-define=NAME=value during flutter run/build.',
        );
      }

      return FirebaseOptions(
        apiKey: AppEnvironment.firebaseApiKey,
        appId: AppEnvironment.firebaseAppId,
        messagingSenderId: AppEnvironment.firebaseMessagingSenderId,
        projectId: AppEnvironment.firebaseProjectId,
        authDomain: AppEnvironment.firebaseAuthDomain,
        storageBucket: AppEnvironment.firebaseStorageBucket,
        measurementId: AppEnvironment.firebaseMeasurementId.isEmpty
            ? null
            : AppEnvironment.firebaseMeasurementId,
      );
    }

    throw StateError(
      'This project is configured for Firebase Web. '
      'For Android/iOS, run `flutterfire configure` to regenerate firebase_options.dart '
      'with platform-specific values.',
    );
  }
}
