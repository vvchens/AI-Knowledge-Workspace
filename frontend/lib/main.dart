import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/project_overview_screen.dart';
import 'screens/projects_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
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
          builder: (context, state) => const ProjectOverviewScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'AI Knowledge Workspace',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
