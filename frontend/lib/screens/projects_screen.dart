import 'package:flutter/material.dart';

import '../components/app_components.dart';
import '../theme/app_tokens.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  static const _projects = [
    _Project(
      name: 'Customer Support Bot',
      description:
          'Automated general answering bot using fresh documentation index.',
      status: 'Active',
      documents: 47,
      members: 12,
      updated: 'Updated 2 hours ago',
    ),
    _Project(
      name: 'Sales Assistant Agent',
      description:
          'RAG powered assistant with access to sales sheets, pricing and CRM scripts.',
      status: 'Active',
      documents: 124,
      members: 8,
      updated: 'Updated 1 day ago',
    ),
    _Project(
      name: 'Legal Compliance Auditor',
      description:
          'Verifies company docs against standardized regulatory lists automatically.',
      status: 'Error',
      documents: 8,
      members: 3,
      updated: 'Updated 3 days ago',
    ),
    _Project(
      name: 'HR Portal Knowledge Search',
      description:
          'Internal employee workspace lookup bot for benefit guides and policies.',
      status: 'Active',
      documents: 98,
      members: 16,
      updated: 'Updated 1 week ago',
    ),
    _Project(
      name: 'Developer Documentation Hub',
      description:
          'Vercel integration docs and API index for engineering onboarding.',
      status: 'Active',
      documents: 312,
      members: 24,
      updated: 'Updated 2 weeks ago',
    ),
    _Project(
      name: 'Archived Campaign Copywriter',
      description:
          'Previous generation writing assistant. Read-only legacy workspace.',
      status: 'Archived',
      documents: 14,
      members: 2,
      updated: 'Updated 1 month ago',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Project> get _filteredProjects {
    final query = _searchController.text.trim().toLowerCase();
    return _projects.where((project) {
      final matchesFilter = _selectedFilter == 'All' ||
          project.status.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesQuery = query.isEmpty ||
          project.name.toLowerCase().contains(query) ||
          project.description.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  void _showNotConnectedMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
                  Icon(Icons.psychology_outlined,
                      color: theme.colorScheme.primary),
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
              onTap: () =>
                  _showNotConnectedMessage('Dashboard is not connected yet.'),
            ),
            _NavigationItem(
              icon: Icons.folder_open_outlined,
              label: 'Projects',
              selected: true,
              onTap: () {},
            ),
            _NavigationItem(
              icon: Icons.description_outlined,
              label: 'Documents',
              onTap: () =>
                  _showNotConnectedMessage('Documents is not connected yet.'),
            ),
            const Spacer(),
            _NavigationItem(
              icon: Icons.people_outline,
              label: 'Users',
              onTap: () =>
                  _showNotConnectedMessage('Users is not connected yet.'),
            ),
            _NavigationItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () =>
                  _showNotConnectedMessage('Settings is not connected yet.'),
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
                        Text('Sarah Jenkins',
                            style: theme.textTheme.labelMedium),
                        Text('Platform Admin',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz,
                      color: theme.colorScheme.onSurfaceVariant),
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
                    Text('Projects', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Create, edit, and audit multi-tenant RAG model sandboxes.',
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
                onPressed: () => _showNotConnectedMessage(
                  'Project creation is not connected yet.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final projects = _filteredProjects;
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
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Active', label: Text('Active')),
                    ButtonSegment(value: 'Archived', label: Text('Archived')),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedFilter = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (projects.isEmpty)
              _buildEmptyState(context)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 600
                          ? 2
                          : 1;
                  final width =
                      (constraints.maxWidth - ((columns - 1) * AppSpacing.lg)) /
                          columns;
                  return Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: projects
                        .map((project) => SizedBox(
                              width: width,
                              child: _buildProjectCard(context, project),
                            ))
                        .toList(),
                  );
                },
              ),
            if (projects.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                '${projects.length} projects',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, _Project project) {
    final theme = Theme.of(context);
    final statusColor = switch (project.status) {
      'Active' => AppColors.success,
      'Error' => theme.colorScheme.error,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        onTap: () =>
            _showNotConnectedMessage('${project.name} is not connected yet.'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppStatusChip(label: project.status, color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              project.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                _ProjectMetric(
                  icon: Icons.description_outlined,
                  value: '${project.documents}',
                  label: 'Documents',
                ),
                const SizedBox(width: AppSpacing.xl),
                _ProjectMetric(
                  icon: Icons.people_outline,
                  value: '${project.members}',
                  label: 'Members',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              project.updated,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        children: [
          Icon(Icons.search_off, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text('No projects found', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try a different search or status filter.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index != 0) {
          _showNotConnectedMessage('This section is not connected yet.');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.folder_open_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Projects',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chat',
        ),
        NavigationDestination(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _Project {
  const _Project({
    required this.name,
    required this.description,
    required this.status,
    required this.documents,
    required this.members,
    required this.updated,
  });

  final String name;
  final String description;
  final String status;
  final int documents;
  final int members;
  final String updated;
}

class _ProjectMetric extends StatelessWidget {
  const _ProjectMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
        const SizedBox(width: AppSpacing.xs),
        Text(label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
      ],
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: selected,
        selectedColor: theme.colorScheme.primary,
        selectedTileColor: theme.colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        onTap: onTap,
      ),
    );
  }
}
