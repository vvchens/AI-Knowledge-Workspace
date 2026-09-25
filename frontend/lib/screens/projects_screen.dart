import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/app_components.dart';
import '../components/app_sidebar.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  List<ProjectRecord> _projects = const [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final projects = await ApiClient.instance.fetchProjects();
      if (!mounted) return;
      setState(() => _projects = projects);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Projects could not be loaded.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateProjectDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final created = await showDialog<ProjectRecord>(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;
        String? formError;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('New Project'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      errorText: formError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          setDialogState(
                              () => formError = 'Enter a project name.');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          formError = null;
                        });
                        try {
                          final project =
                              await ApiClient.instance.createProject(
                            name: name,
                            description: descriptionController.text.trim(),
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(project);
                          }
                        } catch (_) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              isSubmitting = false;
                              formError = 'Project could not be created.';
                            });
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
    nameController.dispose();
    descriptionController.dispose();
    if (created != null && mounted) {
      setState(() => _projects = [created, ..._projects]);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectRecord> get _filteredProjects {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (isDesktop)
                const AppSidebar(section: AppSidebarSection.projects),
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
                onPressed: _showCreateProjectDialog,
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _loadProjects,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
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

  Widget _buildProjectCard(BuildContext context, ProjectRecord project) {
    final theme = Theme.of(context);
    final statusColor = switch (project.status) {
      'active' => AppColors.success,
      'error' => theme.colorScheme.error,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        onTap: () => context.go('/project-overview?projectId=${project.id}'),
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
                AppStatusChip(
                    label: _titleCase(project.status), color: statusColor),
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
              'Updated ${_relativeDate(project.updatedAt)}',
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
            'Create a project to get started.',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This section is not available yet.')),
          );
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

String _titleCase(String value) => value.isEmpty
    ? value
    : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';

String _relativeDate(DateTime date) {
  final difference = DateTime.now().toUtc().difference(date.toLocal());
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${(difference.inDays / 7).floor()}w ago';
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
