import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/app_components.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

void main() {
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
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Knowledge Workspace'),
      ),
      body: Center(
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Phase 1 skeleton',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Open projects',
                icon: Icons.folder_open_outlined,
                onPressed: () => context.go('/projects'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Project list placeholder',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              const AppStatusChip(label: 'Ready', color: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }
}
