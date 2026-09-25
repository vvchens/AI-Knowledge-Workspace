import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../components/app_components.dart';
import '../components/app_sidebar.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

class WorkspaceUser {
  const WorkspaceUser({
    required this.name,
    required this.email,
    required this.role,
    required this.projects,
    required this.status,
    required this.lastActive,
  });

  final String name;
  final String email;
  final String role;
  final int projects;
  final String status;
  final String lastActive;
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, this.loadData = true});

  final bool loadData;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<WorkspaceUser> _users = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.loadData) {
      _loadUsers();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final users = await ApiClient.instance.fetchUsers();
      if (!mounted) return;
      setState(() {
        _users = users
            .map(
              (user) => WorkspaceUser(
                name: user.name,
                email: user.email ?? 'No email provided',
                role: user.role,
                projects: user.projects,
                status: user.status,
                lastActive: _relativeDate(user.lastActive),
              ),
            )
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Users could not be loaded.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WorkspaceUser> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((user) {
      final matchesQuery = query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      final matchesFilter =
          _selectedFilter == 'All' || user.status == _selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _inviteUser() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var role = 'member';
    InvitationRecord? invitation;

    try {
      invitation = await showDialog<InvitationRecord>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Invite user'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: emailController,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        hintText: 'name@company.com',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'member', child: Text('Member')),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => role = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  try {
                    final created = await ApiClient.instance.createInvitation(
                      email: emailController.text.trim(),
                      role: role,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(created);
                    }
                  } catch (_) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Invitation could not be created.')),
                      );
                    }
                  }
                },
                child: const Text('Create invitation'),
              ),
            ],
          ),
        ),
      );
    } finally {
      emailController.dispose();
    }

    if (invitation != null && mounted) {
      await _showInvitationResult(invitation);
    }
  }

  Future<void> _showInvitationResult(InvitationRecord invitation) async {
    final registrationUri = Uri.parse(invitation.registrationPath);
    final hashRoute = Uri(
      path: '/register',
      queryParameters: registrationUri.queryParameters,
    ).toString();
    final link = Uri.base
        .replace(
          path: '/',
          queryParameters: const <String, String>{},
          fragment: hashRoute,
        )
        .toString();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invitation ready'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('This ${invitation.role} invitation expires in 24 hours.'),
            const SizedBox(height: AppSpacing.md),
            SelectableText(link),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Registration link copied.')),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy link'),
          ),
          TextButton.icon(
            onPressed: () =>
                _showMessage(context, 'Email sending is not connected yet.'),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Send email'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (isDesktop) const AppSidebar(section: AppSidebarSection.users),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, isDesktop),
                    Expanded(child: _buildContent(context, isDesktop)),
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
                    Text('Users', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage workspace access and project permissions.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Invite user',
                icon: Icons.person_add_alt_1,
                onPressed: _inviteUser,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final users = _filteredUsers;
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
                  width: isDesktop ? 360 : double.infinity,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Active', label: Text('Active')),
                    ButtonSegment(value: 'Invited', label: Text('Invited')),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedFilter = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_loadError != null)
              _buildLoadError(context)
            else if (users.isEmpty)
              _buildEmptyState(context)
            else if (isDesktop)
              _buildTable(context, users)
            else
              _buildMobileList(context, users),
            if (users.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${users.length} users',
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

  Widget _buildTable(BuildContext context, List<WorkspaceUser> users) {
    final theme = Theme.of(context);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: AppSpacing.xl,
          columns: const [
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Projects')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Last active')),
            DataColumn(label: Text('')),
          ],
          rows: users.map((user) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 250,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(_initials(user.name)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: theme.textTheme.labelLarge),
                              Text(user.email,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(Text(user.role)),
                DataCell(Text('${user.projects}')),
                DataCell(_statusChip(context, user.status)),
                DataCell(Text(user.lastActive)),
                DataCell(
                  IconButton(
                    onPressed: () =>
                        _showMessage(context, 'User actions coming soon.'),
                    icon: const Icon(Icons.more_horiz),
                    tooltip: 'User actions',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<WorkspaceUser> users) {
    return Column(
      children: users
          .map(
            (user) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          child: Text(_initials(user.name)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(user.email,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        _statusChip(context, user.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.sm,
                      children: [
                        Text('Role: ${user.role}'),
                        Text('Projects: ${user.projects}'),
                        Text('Active: ${user.lastActive}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    final color =
        status == 'Active' ? AppColors.success : theme.colorScheme.tertiary;
    return AppStatusChip(label: status, color: color);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.person_search_outlined,
                size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text('No users found', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different search or filter.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Text(_loadError!),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: 3,
      onDestinationSelected: (index) {
        if (index == 0) context.go('/projects');
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

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _relativeDate(DateTime date) {
  final difference = DateTime.now().toUtc().difference(date.toLocal());
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  if (difference.inDays < 1) return '${difference.inHours} hour ago';
  if (difference.inDays < 7) return '${difference.inDays} days ago';
  return '${(difference.inDays / 7).floor()} weeks ago';
}
