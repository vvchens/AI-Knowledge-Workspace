import 'package:flutter/material.dart';

import '../components/app_components.dart';
import '../theme/app_tokens.dart';

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
              Text(
                'Project list placeholder',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              const AppStatusChip(label: 'Ready', color: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }
}
