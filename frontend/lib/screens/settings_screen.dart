import 'package:flutter/material.dart';

import '../components/app_components.dart';
import '../components/app_sidebar.dart';
import '../theme/app_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _weeklyDigest = false;
  bool _autoSaveUploads = true;
  String _defaultModel = 'Balanced';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (isDesktop)
                const AppSidebar(section: AppSidebarSection.settings),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, isDesktop),
                    Expanded(child: _buildContent(context, isDesktop)),
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
                    Text('Settings', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage your workspace preferences and defaults.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Save changes',
                icon: Icons.check,
                onPressed: () => _showMessage(context, 'Settings saved.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              context,
              title: 'Account',
              description: 'Personal details for your workspace account.',
              child: _buildFieldGrid(
                isDesktop,
                const [
                  _ReadOnlyField(label: 'Full name', value: 'Sarah Jenkins'),
                  _ReadOnlyField(
                      label: 'Email address', value: 'sarah@example.com'),
                  _ReadOnlyField(label: 'Role', value: 'Platform Admin'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              title: 'Workspace preferences',
              description: 'Choose how the workspace behaves for you.',
              child: _buildFieldGrid(
                isDesktop,
                [
                  _DropdownField(
                    label: 'Language',
                    value: _language,
                    values: const ['English', '中文', '日本語'],
                    onChanged: (value) => setState(() => _language = value),
                  ),
                  const _ReadOnlyField(
                    label: 'Time zone',
                    value: 'UTC-05:00 Eastern Time',
                  ),
                  _buildSwitchRow(
                    context,
                    title: 'Auto-save uploads',
                    description: 'Save changes as you work.',
                    value: _autoSaveUploads,
                    onChanged: (value) =>
                        setState(() => _autoSaveUploads = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              title: 'Notifications',
              description: 'Control which updates reach your inbox.',
              child: Column(
                children: [
                  _buildSwitchRow(
                    context,
                    title: 'Email notifications',
                    description: 'Receive alerts about workspace activity.',
                    value: _emailNotifications,
                    onChanged: (value) =>
                        setState(() => _emailNotifications = value),
                  ),
                  const Divider(height: AppSpacing.xl),
                  _buildSwitchRow(
                    context,
                    title: 'Weekly digest',
                    description: 'Get a weekly summary of usage and activity.',
                    value: _weeklyDigest,
                    onChanged: (value) => setState(() => _weeklyDigest = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              title: 'AI defaults',
              description: 'Set defaults for new projects and uploads.',
              child: _buildFieldGrid(
                isDesktop,
                [
                  _DropdownField(
                    label: 'Default model',
                    value: _defaultModel,
                    values: const ['Fast', 'Balanced', 'Accurate'],
                    onChanged: (value) =>
                        setState(() => _defaultModel = value),
                  ),
                  const _ReadOnlyField(
                    label: 'Embedding provider',
                    value: 'Workspace default',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              title: 'Danger zone',
              description: 'Irreversible workspace actions.',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: const Text('Delete workspace'),
                subtitle: const Text(
                    'Remove this workspace and all of its projects.'),
                trailing: OutlinedButton(
                  onPressed: () => _showMessage(
                      context, 'Workspace deletion requires confirmation.'),
                  child: const Text('Delete'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String description,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldGrid(bool isDesktop, List<Widget> fields) {
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withSpacing(fields),
      );
    }
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: fields
          .map((field) => SizedBox(width: 410, child: field))
          .toList(),
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final result = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) result.add(const SizedBox(height: AppSpacing.lg));
      result.add(children[index]);
    }
    return result;
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(description),
      value: value,
      onChanged: onChanged,
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (nextValue) {
        if (nextValue != null) onChanged(nextValue);
      },
    );
  }
}