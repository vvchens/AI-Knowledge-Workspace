import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/app_components.dart';
import '../theme/app_tokens.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (isDesktop) _buildNavigationRail(context),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, isDesktop),
                    Expanded(child: _buildContent(context)),
                    if (!isDesktop) _buildMobileNavigation(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 240,
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'AI Knowledge',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _NavigationItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: true,
              onTap: () => context.go('/dashboard'),
            ),
            _NavigationItem(
              icon: Icons.folder_open_outlined,
              label: 'Projects',
              onTap: () => context.go('/projects'),
            ),
            _NavigationItem(
              icon: Icons.description_outlined,
              label: 'Documents',
              onTap: () => _showMessage(context, 'Documents is not connected yet.'),
            ),
            _NavigationItem(
              icon: Icons.assessment_outlined,
              label: 'Evaluation',
              onTap: () => _showMessage(context, 'Evaluation is not connected yet.'),
            ),
            const Spacer(),
            _NavigationItem(
              icon: Icons.people_outline,
              label: 'Users',
              onTap: () => _showMessage(context, 'Users is not connected yet.'),
            ),
            _NavigationItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => _showMessage(context, 'Settings is not connected yet.'),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      'SJ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sarah Jenkins', style: theme.textTheme.labelMedium),
                        Text(
                          'Platform Admin',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? AppSpacing.xxl : AppSpacing.lg,
            AppSpacing.lg,
            isDesktop ? AppSpacing.xxl : AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              if (!isDesktop)
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open navigation',
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Here is a general overview of your workspace cluster activity.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'New Project',
                icon: Icons.add,
                onPressed: () => _showMessage(context, 'Project creation is not connected yet.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 960
                    ? 4
                    : constraints.maxWidth >= 700
                        ? 2
                        : 1;
                final gap = AppSpacing.lg;
                final available = constraints.maxWidth - (gap * (crossAxisCount - 1));
                final cardWidth = available / crossAxisCount;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _MetricCard(
                        label: 'Total Projects',
                        value: '12',
                        helper: '+2 this month',
                        accent: AppColors.info,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _MetricCard(
                        label: 'Active Users',
                        value: '48',
                        helper: '12 online now',
                        accent: AppColors.success,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _MetricCard(
                        label: 'Documents Indexed',
                        value: '1,247',
                        helper: '99.8% search efficiency',
                        accent: AppColors.warning,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _MetricCard(
                        label: 'Queries Today',
                        value: '326',
                        helper: 'Avg response 1.2s',
                        accent: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 840;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _RecentActivityPanel(),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: _ProjectHealthPanel(),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _RecentActivityPanel(),
                          const SizedBox(height: AppSpacing.lg),
                          _ProjectHealthPanel(),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) context.go('/projects');
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.folder_open_outlined), label: 'Projects'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.accent,
  });

  final String label;
  final String value;
  final String helper;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            helper,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _ActivityItem(
        title: "John Doe uploaded 'compliance_q4.pdf'",
        time: '10 mins ago',
      ),
      _ActivityItem(
        title: 'System Evaluation run completed for Customer Support Bot',
        time: '25 mins ago',
      ),
      _ActivityItem(
        title: "Sarah Jenkins created new project 'HR Portal'",
        time: '1 hour ago',
      ),
      _ActivityItem(
        title: "System Document parsing failed on 'api_spec_v2_broken.md'",
        time: '3 hours ago',
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.time,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({required this.title, required this.time});

  final String title;
  final String time;
}

class _ProjectHealthPanel extends StatelessWidget {
  const _ProjectHealthPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projects = [
      _HealthProject(name: 'Customer Support Bot', status: 'Active', health: 94.2, docs: 47, queries: 189),
      _HealthProject(name: 'Sales Assistant Agent', status: 'Processing', health: 91.8, docs: 124, queries: 54),
      _HealthProject(name: 'Legal Compliance Auditor', status: 'Error', health: 0, docs: 8, queries: 0),
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Health Summary',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppStatusChip(
                        label: project.status,
                        color: project.status == 'Error'
                            ? theme.colorScheme.error
                            : project.status == 'Processing'
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${project.docs} indexed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${project.queries} queries today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    value: project.status == 'Error' ? 0 : project.health / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      project.status == 'Error'
                          ? theme.colorScheme.error
                          : project.status == 'Processing'
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      project.status == 'Error' ? 'N/A' : '${project.health.toStringAsFixed(1)}% accuracy',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthProject {
  const _HealthProject({
    required this.name,
    required this.status,
    required this.health,
    required this.docs,
    required this.queries,
  });

  final String name;
  final String status;
  final double health;
  final int docs;
  final int queries;
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Material(
        color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
