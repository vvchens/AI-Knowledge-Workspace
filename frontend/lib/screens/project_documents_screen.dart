import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../components/app_components.dart';
import '../components/app_sidebar.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

class ProjectDocumentsScreen extends StatefulWidget {
  const ProjectDocumentsScreen({super.key, this.projectId});

  final String? projectId;

  @override
  State<ProjectDocumentsScreen> createState() => _ProjectDocumentsScreenState();
}

class _ProjectDocumentsScreenState extends State<ProjectDocumentsScreen> {
  late final Future<ProjectRecord> _projectFuture;
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  List<DocumentRecord> _documents = const [];
  bool _isLoadingDocuments = true;
  bool _isUploading = false;
  String? _deletingDocumentId;
  String? _documentError;

  @override
  void initState() {
    super.initState();
    _projectFuture = widget.projectId == null
        ? Future.error(const FormatException('Missing project ID.'))
        : ApiClient.instance.fetchProject(widget.projectId!);
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final projectId = widget.projectId;
    if (projectId == null) return;
    try {
      final documents = await ApiClient.instance.fetchDocuments(projectId);
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _documentError = null;
        _isLoadingDocuments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _documentError = 'Documents could not be loaded.';
        _isLoadingDocuments = false;
      });
    }
  }

  Future<void> _uploadDocument() async {
    final projectId = widget.projectId;
    if (projectId == null || _isUploading) return;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'txt', 'md'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isUploading = true;
      _documentError = null;
    });
    try {
      final document = await ApiClient.instance.uploadDocument(
        projectId: projectId,
        file: result.files.single,
      );
      if (!mounted) return;
      setState(() => _documents = [document, ..._documents]);
      _showMessage('Document uploaded and queued for indexing.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _documentError = 'Document could not be uploaded.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(DocumentRecord document) async {
    final projectId = widget.projectId;
    if (projectId == null || _deletingDocumentId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
            '"${document.name}" and its indexed content will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingDocumentId = document.id;
      _documentError = null;
    });
    try {
      await ApiClient.instance.deleteDocument(
        projectId: projectId,
        documentId: document.id,
      );
      if (!mounted) return;
      setState(() => _documents.removeWhere((item) => item.id == document.id));
      _showMessage('Document deleted.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _documentError = 'Document could not be deleted.');
    } finally {
      if (mounted) setState(() => _deletingDocumentId = null);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              if (isDesktop)
                AppSidebar(
                  section: AppSidebarSection.documents,
                  projectId: widget.projectId,
                ),
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
                    Text('Documents', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      project.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Upload document',
                icon: Icons.upload_file_outlined,
                onPressed: _isUploading ? null : _uploadDocument,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProjectRecord project) {
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
                      hintText: 'Search documents...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Indexed', label: Text('Indexed')),
                    ButtonSegment(
                        value: 'Processing', label: Text('Processing')),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedFilter = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_documentError != null)
              _buildDocumentError(context)
            else if (_isLoadingDocuments)
              const Center(child: CircularProgressIndicator())
            else if (_filteredDocuments.isEmpty)
              _buildEmptyState(context)
            else
              ..._filteredDocuments.map((document) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildDocumentCard(context, document),
                  )),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '${_documents.length} documents uploaded',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
        if (index == 0) return;
        _showUnavailable(context);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Documents',
        ),
        NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document upload is not connected yet.')),
    );
  }

  List<DocumentRecord> get _filteredDocuments {
    final query = _searchController.text.trim().toLowerCase();
    return _documents.where((document) {
      final matchesFilter = _selectedFilter == 'All' ||
          document.status.toLowerCase() == _selectedFilter.toLowerCase();
      return matchesFilter && document.name.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          children: [
            Icon(Icons.description_outlined,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text('No documents found', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _documents.isEmpty
                  ? 'Upload a document to start building this project’s knowledge base.'
                  : 'Try a different search or status filter.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_documents.isEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Upload your first document',
                icon: Icons.upload_file_outlined,
                onPressed: _isUploading ? null : _uploadDocument,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentError(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(_documentError!),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _loadDocuments,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, DocumentRecord document) {
    final theme = Theme.of(context);
    final statusColor = document.status.toLowerCase() == 'indexed'
        ? AppColors.success
        : AppColors.warning;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined,
              color: theme.colorScheme.primary, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_formatBytes(document.sizeBytes)} · ${document.contentType ?? 'Unknown type'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppStatusChip(label: _titleCase(document.status), color: statusColor),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: _deletingDocumentId == null
                ? () => _deleteDocument(document)
                : null,
            icon: _deletingDocumentId == document.id
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            tooltip: 'Delete document',
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _titleCase(String value) => value.isEmpty
    ? value
    : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
