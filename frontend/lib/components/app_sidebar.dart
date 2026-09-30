import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_client.dart';
import '../theme/app_tokens.dart';

enum AppSidebarSection {
  dashboard,
  projects,
  documents,
  users,
  organizations,
  settings,
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.section,
    super.key,
    this.projectId,
  });

  final AppSidebarSection section;
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseUser =
        Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
    final currentUser = ApiClient.instance.currentUser;
    final displayName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!.trim()
        : firebaseUser?.displayName?.trim().isNotEmpty == true
            ? firebaseUser!.displayName!.trim()
            : currentUser?.email ?? firebaseUser?.email ?? 'Workspace user';
    final role = currentUser?.systemRole == 'system_admin'
        ? 'System Admin'
        : currentUser?.systemRole == 'admin'
            ? 'Admin'
            : 'Member';
    final initials = _initials(displayName);
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
            _AppSidebarItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: section == AppSidebarSection.dashboard,
              onTap: () => context.go('/dashboard'),
            ),
            _AppSidebarItem(
              icon: Icons.folder_open_outlined,
              label: 'Projects',
              selected: section == AppSidebarSection.projects,
              onTap: () => context.go('/projects'),
            ),
            _AppSidebarItem(
              icon: Icons.description_outlined,
              label: 'Documents',
              selected: section == AppSidebarSection.documents,
              onTap: () => _openDocuments(context),
            ),
            _AppSidebarItem(
              icon: Icons.assessment_outlined,
              label: 'Evaluation',
              onTap: () =>
                  _showMessage(context, 'Evaluation is not connected yet.'),
            ),
            const Spacer(),
            _AppSidebarItem(
              icon: Icons.people_outline,
              label: 'Users',
              selected: section == AppSidebarSection.users,
              onTap: () => context.go('/users'),
            ),
            if (ApiClient.instance.canAccessOrganizations)
              _AppSidebarItem(
                icon: Icons.business_outlined,
                label: 'Organizations',
                selected: section == AppSidebarSection.organizations,
                onTap: () => context.go('/organizations'),
              ),
            _AppSidebarItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: section == AppSidebarSection.settings,
              onTap: () => context.go('/settings'),
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
                      initials,
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
                        Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(
                          role,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Account menu',
                    icon: Icon(Icons.more_horiz,
                        color: theme.colorScheme.onSurfaceVariant),
                    onSelected: (value) {
                      if (value == 'logout') _logout(context);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.logout),
                          title: Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final values = parts.toList();
    if (values.isEmpty) return '?';
    if (values.length == 1) return values.first.substring(0, 1).toUpperCase();
    return '${values.first.substring(0, 1)}${values.last.substring(0, 1)}'
        .toUpperCase();
  }

  void _openDocuments(BuildContext context) {
    if (projectId == null) {
      _showMessage(context, 'Select a project to view documents.');
      return;
    }
    context.go(Uri(
      path: '/project-documents',
      queryParameters: {'projectId': projectId},
    ).toString());
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await ApiClient.instance.logout();
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
      if (context.mounted) context.go('/login');
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Logout could not be completed.');
      }
    }
  }
}

class _AppSidebarItem extends StatelessWidget {
  const _AppSidebarItem({
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Material(
        color:
            selected ? theme.colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
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
