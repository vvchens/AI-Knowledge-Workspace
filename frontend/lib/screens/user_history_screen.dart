import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/app_sidebar.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({required this.projectId, super.key});

  final String projectId;

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  late Future<List<ConversationRecord>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture =
        ApiClient.instance.fetchConversations(widget.projectId);
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

  Widget _buildContent(BuildContext context) {
    return FutureBuilder<List<ConversationRecord>>(
      future: _conversationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Conversation history could not be loaded.'),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _conversationsFuture =
                        ApiClient.instance.fetchConversations(widget.projectId);
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final conversations = snapshot.data ?? const [];
        if (conversations.isEmpty) return _buildEmptyState(context);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                leading: const CircleAvatar(
                  child: Icon(Icons.chat_bubble_outline),
                ),
                title: Text(conversation.title),
                subtitle: Text(
                  '${conversation.messageCount} messages  ·  ${_dateLabel(conversation.updatedAt)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(
                  Uri(
                    path: '/project-chat',
                    queryParameters: {
                      'projectId': widget.projectId,
                      'conversationId': conversation.id,
                    },
                  ).toString(),
                ),
              ),
            );
          },
        );
      },
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
              IconButton(
                onPressed: () => context.go(
                  Uri(
                    path: '/project-chat',
                    queryParameters: {'projectId': widget.projectId},
                  ).toString(),
                ),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to chat',
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Conversation history',
                  style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text('No conversations yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your saved questions and answers will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go(
                Uri(
                  path: '/project-chat',
                  queryParameters: {'projectId': widget.projectId},
                ).toString(),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Start a conversation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: 2,
      onDestinationSelected: (index) {
        if (index == 0) context.go('/projects');
        if (index == 1) {
          context.go(Uri(
            path: '/project-chat',
            queryParameters: {'projectId': widget.projectId},
          ).toString());
        }
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.folder_open_outlined), label: 'Projects'),
        NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

String _dateLabel(DateTime date) {
  final localDate = date.toLocal();
  return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
}
