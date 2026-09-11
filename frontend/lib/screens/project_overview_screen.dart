import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/app_components.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

class ProjectOverviewScreen extends StatefulWidget {
  const ProjectOverviewScreen({super.key, this.projectId});

  final String? projectId;

  @override
  State<ProjectOverviewScreen> createState() => _ProjectOverviewScreenState();
}

class _ProjectOverviewScreenState extends State<ProjectOverviewScreen> {
  late final Future<ProjectRecord> _projectFuture;
  final _searchController = TextEditingController();
  List<SearchResultRecord> _searchResults = const [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _projectFuture = widget.projectId == null
        ? Future.error(const FormatException('Missing project ID.'))
        : ApiClient.instance.fetchProject(widget.projectId!);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProject() async {
    final projectId = widget.projectId;
    final query = _searchController.text.trim();
    if (projectId == null || query.isEmpty || _isSearching) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final results = await ApiClient.instance.searchProject(
        projectId: projectId,
        query: query,
      );
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchError = 'Search could not be completed.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProjectRecord>(
      future: _projectFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text(
                  snapshot.error?.toString() ?? 'Project could not be loaded.'),
            ),
          );
        }
        return _buildScaffold(context, snapshot.data!);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, ProjectRecord project) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 980;
          return Row(
            children: [
              if (isDesktop) _buildNavigationRail(context),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, isDesktop, project),
                    Expanded(child: _buildContent(context, project)),
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
              onTap: () => context.go(
                '/project-documents?projectId=${widget.projectId}',
              ),
            ),
            _NavigationItem(
              icon: Icons.assessment_outlined,
              label: 'Evaluation',
              onTap: () =>
                  _showMessage(context, 'Evaluation is not connected yet.'),
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
              onTap: () =>
                  _showMessage(context, 'Settings is not connected yet.'),
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
                        Text(
                          'Platform Admin',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
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

  Widget _buildHeader(
      BuildContext context, bool isDesktop, ProjectRecord project) {
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
                    Text(project.name, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      project.description.isEmpty
                          ? 'Project'
                          : project.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Overview',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProjectRecord project) {
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
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                      label: 'Documents',
                      value: '${project.documents}',
                      detail: 'Indexed documents'),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _MiniStatCard(
                      label: 'Members',
                      value: '${project.members}',
                      detail: 'Project members'),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _MiniStatCard(
                      label: 'Status',
                      value: project.status,
                      detail: 'Current project status'),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _MiniStatCard(
                      label: 'Updated',
                      value: _dateLabel(project.updatedAt),
                      detail: 'Last database update'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSearchPanel(context),
            const SizedBox(height: AppSpacing.xxl),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                              flex: 2,
                              child: _EmptyPanel(
                                  title: 'Recent Conversations',
                                  message:
                                      'No conversations are available yet.')),
                          const SizedBox(width: AppSpacing.lg),
                          const Expanded(
                              child: _EmptyPanel(
                                  title: 'Configuration',
                                  message:
                                      'Project configuration is not available yet.')),
                        ],
                      )
                    : Column(
                        children: [
                          const _EmptyPanel(
                              title: 'Recent Conversations',
                              message: 'No conversations are available yet.'),
                          const SizedBox(height: AppSpacing.lg),
                          const _EmptyPanel(
                              title: 'Configuration',
                              message:
                                  'Project configuration is not available yet.'),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPanel(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Search knowledge', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _searchProject(),
            decoration: InputDecoration(
              hintText: 'Ask about this project...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: _isSearching ? null : _searchProject,
                icon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                tooltip: 'Search',
              ),
            ),
          ),
          if (_searchError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_searchError!, style: TextStyle(color: theme.colorScheme.error)),
          ] else if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ..._searchResults.map((result) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(result.documentName),
                    subtitle: Text(
                      '${result.content}${result.pageNumber == null ? '' : '\nPage ${result.pageNumber}'}',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )),
          ] else if (_searchController.text.trim().isNotEmpty && !_isSearching) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('No matching knowledge found.', style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 0) context.go('/dashboard');
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        NavigationDestination(
            icon: Icon(Icons.folder_open_outlined), label: 'Projects'),
        NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _dateLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.lg),
          Text(message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

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
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
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
