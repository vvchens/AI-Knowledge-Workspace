import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/app_components.dart';
import '../theme/app_tokens.dart';

class ProjectOverviewScreen extends StatelessWidget {
  const ProjectOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              selected: true,
              onTap: () {},
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
                    Text('Customer Support Bot', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Workspace Platform',
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
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(label: 'Documents', value: '47', detail: '892KB total size'),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _MiniStatCard(label: 'Active Users', value: '12', detail: '3 departments'),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _MiniStatCard(label: 'Conversations', value: '892', detail: 'All sessions'),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _MiniStatCard(label: 'Avg Response Time', value: '1.2s', detail: 'Avg token time'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _RecentConversationsPanel()),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(child: _ConfigurationSummaryPanel()),
                        ],
                      )
                    : Column(
                        children: [
                          _RecentConversationsPanel(),
                          const SizedBox(height: AppSpacing.lg),
                          _ConfigurationSummaryPanel(),
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
        if (index == 0) context.go('/dashboard');
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

class _RecentConversationsPanel extends StatelessWidget {
  const _RecentConversationsPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conversations = [
      _ConversationItem(
        user: 'user_902',
        time: '5m ago',
        question: 'How do I return a damaged box?',
        answer: 'You can file a return request under your account settings.',
      ),
      _ConversationItem(
        user: 'user_451',
        time: '18m ago',
        question: 'Is international shipping free?',
        answer: 'International orders qualify for free delivery if...',
      ),
      _ConversationItem(
        user: 'user_122',
        time: '1h ago',
        question: 'What is your refund policy?',
        answer: 'Refunds are processed within 5-7 business days to the...',
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Conversations',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...conversations.map(
            (conversation) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.user,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          conversation.time,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Q: ${conversation.question}', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('A: ${conversation.answer}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationItem {
  const _ConversationItem({
    required this.user,
    required this.time,
    required this.question,
    required this.answer,
  });

  final String user;
  final String time;
  final String question;
  final String answer;
}

class _ConfigurationSummaryPanel extends StatelessWidget {
  const _ConfigurationSummaryPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = [
      _ConfigRow(label: 'LLM Model', value: 'gpt-4o-mini (OpenAI)'),
      _ConfigRow(label: 'Embedding Model', value: 'text-embedding-3-small'),
      _ConfigRow(label: 'Retrieval Strategy', value: 'Cosine Similarity + Re-ranker'),
      _ConfigRow(label: 'Chunk Size Settings', value: '512 tokens (10% overlap)'),
      _ConfigRow(label: 'Temperature', value: '0.2 (Focused & Grounded)'),
      _ConfigRow(label: 'System Guardrails', value: 'Enabled (PII Masking, Toxicity)'),
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration Summary',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...config.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.value,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium,
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

class _ConfigRow {
  const _ConfigRow({required this.label, required this.value});

  final String label;
  final String value;
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
