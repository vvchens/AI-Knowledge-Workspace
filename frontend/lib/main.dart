import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'services/api_client.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/project_overview_screen.dart';
import 'screens/project_documents_screen.dart';
import 'screens/projects_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _restoreBackendSession();
    } else {
      debugPrint(
        'Native Firebase config is not ready yet. Run flutterfire configure for Android/iOS.',
      );
    }
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }

  runApp(const ProviderScope(child: App()));
}

Future<void> _restoreBackendSession() async {
  final auth = FirebaseAuth.instance;
  final user = await auth.authStateChanges().first;
  if (user == null) return;

  final idToken = await user.getIdToken(true);
  if (idToken == null) return;

  await ApiClient.instance.createBackendSession(idToken);
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) => '/login',
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
        ),
        GoRoute(
          path: '/project-overview',
          builder: (context, state) => ProjectOverviewScreen(
            projectId: state.uri.queryParameters['projectId'],
          ),
        ),
        GoRoute(
          path: '/project-documents',
          builder: (context, state) => ProjectDocumentsScreen(
            projectId: state.uri.queryParameters['projectId'],
          ),
        ),
      ],
    );

    ApiClient.instance.onSessionExpired = () async {
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseAuth.instance.signOut();
        }
      } catch (error) {
        debugPrint('Firebase sign-out after session expiry failed: $error');
      }
      if (router.state.uri.path != '/login') {
        router.go('/login');
      }
    };

    return MaterialApp.router(
      title: 'AI Knowledge Workspace',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
