import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/app_components.dart';
import '../components/app_sidebar.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({super.key, this.loadData = true});

  final bool loadData;

  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<OrganizationRecord> _organizations = const [];
  List<UserRecord> _users = const [];

  @override
  void initState() {
    super.initState();
    if (widget.loadData) {
      _loadData();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient.instance.fetchOrganizations(),
        ApiClient.instance.fetchUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _organizations = results[0] as List<OrganizationRecord>;
        _users = results[1] as List<UserRecord>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Organizations could not be loaded.';
        _isLoading = false;
      });
    }
  }

  Future<void> _createOrganization() async {
    final result = await _showOrganizationDialog();
    if (result == null || !mounted) return;
    try {
      final organization = await ApiClient.instance.createOrganization(
        name: result.name,
        slug: result.slug,
      );
      setState(() => _organizations = [..._organizations, organization]);
      _showMessage('Organization created.');
    } catch (_) {
      _showMessage('Organization could not be created.');
    }
  }

  Future<void> _editOrganization(OrganizationRecord organization) async {
    final result = await _showOrganizationDialog(organization: organization);
    if (result == null || !mounted) return;
    try {
      final updated = await ApiClient.instance.updateOrganization(
        organizationId: organization.id,
        name: result.name,
        slug: result.slug,
      );
      setState(() {
        _organizations = _organizations
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
      _showMessage('Organization updated.');
    } catch (_) {
      _showMessage('Organization could not be updated.');
    }
  }

  Future<void> _disableOrganization(OrganizationRecord organization) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disable organization?'),
        content: Text(
          'Users will no longer be able to use ${organization.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final updated =
          await ApiClient.instance.disableOrganization(organization.id);
      setState(() {
        _organizations = _organizations
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
      _showMessage('Organization disabled.');
    } catch (_) {
      _showMessage('Organization could not be disabled.');
    }
  }

  Future<void> _setAdmin(OrganizationRecord organization) async {
    if (_users.isEmpty) {
      _showMessage('No users are available to assign.');
      return;
    }
    final user = await showDialog<UserRecord>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Set admin for ${organization.name}'),
        children: _users
            .map(
              (user) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(user),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(_initials(user.name)),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email ?? 'No email provided'),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (user == null || !mounted) return;
    try {
      await ApiClient.instance.setOrganizationAdmin(
        organizationId: organization.id,
        userId: user.id,
      );
      _showMessage('${user.name} is now an organization admin.');
    } catch (_) {
      _showMessage('Organization admin could not be assigned.');
    }
  }

  Future<_OrganizationFormResult?> _showOrganizationDialog({
    OrganizationRecord? organization,
  }) async {
    final nameController = TextEditingController(text: organization?.name);
    final slugController = TextEditingController(text: organization?.slug);
    final formKey = GlobalKey<FormState>();
    try {
      return await showDialog<_OrganizationFormResult>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
              organization == null ? 'New organization' : 'Edit organization'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: organization == null,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter an organization name.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: slugController,
                    decoration: const InputDecoration(
                      labelText: 'Slug',
                      hintText: 'acme-brokerage',
                    ),
                    validator: (value) {
                      final slug = value?.trim() ?? '';
                      if (!RegExp(r'^[a-z0-9-]+$').hasMatch(slug)) {
                        return 'Use lowercase letters, numbers, and hyphens.';
                      }
                      return null;
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
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.of(dialogContext).pop(
                  _OrganizationFormResult(
                    name: nameController.text.trim(),
                    slug: slugController.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      nameController.dispose();
      slugController.dispose();
    }
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
                const AppSidebar(section: AppSidebarSection.organizations),
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
                    Text('Organizations', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage tenant boundaries and organization administrators.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'New organization',
                icon: Icons.add_business_outlined,
                onPressed: _createOrganization,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDesktop) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_organizations.isEmpty) {
      return const Center(child: Text('No organizations found'));
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
        child: isDesktop ? _buildTable(context) : _buildList(context),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    return Card(
      child: DataTable(
        columnSpacing: AppSpacing.xl,
        columns: const [
          DataColumn(label: Text('Organization')),
          DataColumn(label: Text('Slug')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _organizations
            .map(
              (organization) => DataRow(
                cells: [
                  DataCell(Text(organization.name)),
                  DataCell(Text(organization.slug)),
                  DataCell(AppStatusChip(
                    label: organization.status,
                    color: organization.status == 'active'
                        ? AppColors.success
                        : AppColors.warning,
                  )),
                  DataCell(_buildActions(organization)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return Column(
      children: _organizations
          .map(
            (organization) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(organization.name,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        AppStatusChip(
                          label: organization.status,
                          color: organization.status == 'active'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(organization.slug),
                    const SizedBox(height: AppSpacing.md),
                    _buildActions(organization),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActions(OrganizationRecord organization) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        TextButton.icon(
          onPressed: () => _setAdmin(organization),
          icon: const Icon(Icons.admin_panel_settings_outlined),
          label: const Text('Set admin'),
        ),
        IconButton(
          onPressed: () => _editOrganization(organization),
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit organization',
        ),
        if (organization.status == 'active')
          IconButton(
            onPressed: () => _disableOrganization(organization),
            icon: const Icon(Icons.block_outlined),
            tooltip: 'Disable organization',
          ),
      ],
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 0) return;
        if (index == 1) context.go('/projects');
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.business_outlined), label: 'Organizations'),
        NavigationDestination(
            icon: Icon(Icons.folder_open_outlined), label: 'Projects'),
        NavigationDestination(icon: Icon(Icons.people_outline), label: 'Users'),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OrganizationFormResult {
  const _OrganizationFormResult({required this.name, required this.slug});

  final String name;
  final String slug;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
