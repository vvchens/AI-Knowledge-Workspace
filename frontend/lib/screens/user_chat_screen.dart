import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/app_components.dart';
import '../components/app_sidebar.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({
    required this.projectId,
    this.conversationId,
    super.key,
  });

  final String projectId;
  final String? conversationId;

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  late final Future<ProjectRecord> _projectFuture;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatTurn> _turns = [];
  String? _conversationId;
  bool _isSubmitting = false;
  bool _isLoadingConversation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _projectFuture = ApiClient.instance.fetchProject(widget.projectId);
    _conversationId = widget.conversationId;
    if (_conversationId != null) _loadConversation();
  }

  Future<void> _loadConversation() async {
    setState(() => _isLoadingConversation = true);
    try {
      final conversation = await ApiClient.instance.fetchConversation(
        projectId: widget.projectId,
        conversationId: _conversationId!,
      );
      final turns = <_ChatTurn>[];
      for (var index = 0; index < conversation.messages.length; index++) {
        final message = conversation.messages[index];
        if (message.role != 'user') continue;
        SearchResponseRecord? response;
        if (index + 1 < conversation.messages.length &&
            conversation.messages[index + 1].role == 'assistant') {
          final assistant = conversation.messages[index + 1];
          response = SearchResponseRecord(
            rewrittenQuery: '',
            answer: assistant.content,
            results: assistant.citations
                .map(_citationToResult)
                .whereType<SearchResultRecord>()
                .toList(),
          );
          index++;
        }
        turns.add(_ChatTurn(question: message.content, response: response));
      }
      if (!mounted) return;
      setState(() => _turns
        ..clear()
        ..addAll(turns));
      _scrollToEnd();
    } catch (_) {
      if (mounted) setState(() => _error = 'Conversation could not be loaded.');
    } finally {
      if (mounted) setState(() => _isLoadingConversation = false);
    }
  }

  SearchResultRecord? _citationToResult(Map<String, dynamic> citation) {
    final documentId = citation['document_id'] as String?;
    final documentName = citation['document_name'] as String?;
    final content = citation['content'] as String?;
    if (documentId == null || documentName == null || content == null) {
      return null;
    }
    return SearchResultRecord(
      documentId: documentId,
      documentName: documentName,
      content: content,
      pageNumber: citation['page_number'] as int?,
      score: (citation['score'] as num? ?? 0).toDouble(),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _inputController.text.trim();
    if (question.isEmpty || _isSubmitting) return;

    _inputController.clear();
    setState(() {
      _error = null;
      _isSubmitting = true;
      _turns.add(_ChatTurn(question: question));
    });
    _scrollToEnd();

    try {
      final response = await ApiClient.instance.sendProjectMessage(
        projectId: widget.projectId,
        query: question,
        conversationId: _conversationId,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = response.conversationId;
        _turns[_turns.length - 1] = _ChatTurn(
          question: question,
          response: response,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'The answer could not be generated. Please try again.';
        _turns.removeLast();
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _scrollToEnd();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
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
          final isDesktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (isDesktop)
                const AppSidebar(section: AppSidebarSection.projects),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, isDesktop, project),
                    Expanded(child: _buildContent(context, project, isDesktop)),
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
              IconButton(
                onPressed: () => context.go('/projects'),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to projects',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Ask questions about the project knowledge base.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.go(
                  Uri(
                          path: '/project-history',
                          queryParameters: {'projectId': widget.projectId})
                      .toString(),
                ),
                icon: const Icon(Icons.history),
                tooltip: 'Conversation history',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ProjectRecord project, bool isDesktop) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: _isLoadingConversation
              ? const Center(child: CircularProgressIndicator())
              : _turns.isEmpty
                  ? _buildWelcome(context, project)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? AppSpacing.xxl : AppSpacing.lg,
                        AppSpacing.lg,
                        isDesktop ? AppSpacing.xxl : AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: _turns.length,
                      itemBuilder: (context, index) =>
                          _buildTurn(context, _turns[index]),
                    ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child:
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ),
        _buildComposer(context, isDesktop),
      ],
    );
  }

  Widget _buildWelcome(BuildContext context, ProjectRecord project) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            children: [
              Icon(Icons.auto_awesome,
                  size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.lg),
              Text('What would you like to know?',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                project.description.isEmpty
                    ? 'Ask a question and get an answer grounded in this project.'
                    : project.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  _SuggestionChip(label: 'Summarize the key topics'),
                  _SuggestionChip(label: 'Find relevant guidance'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurn(BuildContext context, _ChatTurn turn) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 720),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(turn.question),
            ),
          ),
          if (turn.response != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SelectableText(
                    turn.response!.answer.isEmpty
                        ? 'No answer was returned for this question.'
                        : turn.response!.answer,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (turn.response!.results.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SourceList(results: turn.response!.results),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildComposer(BuildContext context, bool isDesktop) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? AppSpacing.xxl : AppSpacing.lg,
            AppSpacing.sm,
            isDesktop ? AppSpacing.xxl : AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: TextField(
              controller: _inputController,
              enabled: !_isSubmitting,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => _ask(),
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                prefixIcon: const Icon(Icons.chat_bubble_outline),
                suffixIcon: IconButton(
                  onPressed: _isSubmitting ? null : _ask,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_upward),
                  tooltip: 'Send question',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: 1,
      onDestinationSelected: (index) {
        if (index == 0) context.go('/projects');
        if (index == 2) {
          context.go(Uri(
              path: '/project-history',
              queryParameters: {'projectId': widget.projectId}).toString());
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

class _ChatTurn {
  const _ChatTurn({required this.question, this.response});

  final String question;
  final SearchResponseRecord? response;
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {},
    );
  }
}

class _SourceList extends StatelessWidget {
  const _SourceList({required this.results});

  final List<SearchResultRecord> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sources', style: theme.textTheme.titleMedium),
          ...results.map(
            (result) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(result.documentName),
              subtitle: Text(
                '${result.content}${result.pageNumber == null ? '' : '\nPage ${result.pageNumber}'}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
