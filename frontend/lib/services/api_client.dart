import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../environment.dart';

class ProjectRecord {
  const ProjectRecord({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.documents,
    required this.members,
    required this.updatedAt,
  });

  factory ProjectRecord.fromJson(Map<String, dynamic> json) {
    return ProjectRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String,
      documents: json['documents'] as int? ?? 0,
      members: json['members'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String name;
  final String description;
  final String status;
  final int documents;
  final int members;
  final DateTime updatedAt;
}

class DocumentRecord {
  const DocumentRecord({
    required this.id,
    required this.name,
    required this.contentType,
    required this.sizeBytes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentRecord.fromJson(Map<String, dynamic> json) {
    return DocumentRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      contentType: json['content_type'] as String?,
      sizeBytes: json['size_bytes'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String name;
  final String? contentType;
  final int sizeBytes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class UserRecord {
  const UserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.projects,
    required this.status,
    required this.lastActive,
  });

  factory UserRecord.fromJson(Map<String, dynamic> json) {
    return UserRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      projects: json['projects'] as int,
      status: json['status'] as String,
      lastActive: DateTime.parse(json['last_active'] as String),
    );
  }

  final String id;
  final String name;
  final String? email;
  final String role;
  final int projects;
  final String status;
  final DateTime lastActive;
}

class InvitationRecord {
  const InvitationRecord({
    required this.email,
    required this.role,
    required this.registrationPath,
    required this.expiresAt,
  });

  factory InvitationRecord.fromJson(Map<String, dynamic> json) {
    return InvitationRecord(
      email: json['email'] as String,
      role: json['role'] as String,
      registrationPath: json['registration_path'] as String? ?? '',
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final String email;
  final String role;
  final String registrationPath;
  final DateTime expiresAt;
}

class SearchResultRecord {
  const SearchResultRecord({
    required this.documentId,
    required this.documentName,
    required this.content,
    required this.pageNumber,
    required this.score,
  });

  factory SearchResultRecord.fromJson(Map<String, dynamic> json) {
    return SearchResultRecord(
      documentId: json['document_id'] as String,
      documentName: json['document_name'] as String,
      content: json['content'] as String,
      pageNumber: json['page_number'] as int?,
      score: (json['score'] as num).toDouble(),
    );
  }

  final String documentId;
  final String documentName;
  final String content;
  final int? pageNumber;
  final double score;
}

class SearchResponseRecord {
  const SearchResponseRecord({
    required this.rewrittenQuery,
    required this.answer,
    required this.results,
  });

  factory SearchResponseRecord.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>? ?? const [];
    return SearchResponseRecord(
      rewrittenQuery: json['rewritten_query'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      results: results
          .map((result) =>
              SearchResultRecord.fromJson(result as Map<String, dynamic>))
          .toList(),
    );
  }

  final String rewrittenQuery;
  final String answer;
  final List<SearchResultRecord> results;
}

class ApiClient {
  ApiClient._() : _dio = Dio(BaseOptions(baseUrl: AppEnvironment.apiBaseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            _sessionToken = null;
            await onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  final Dio _dio;
  String? _sessionToken;
  Future<void> Function()? onSessionExpired;

  Future<void> createBackendSession(String firebaseIdToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/firebase/session',
      data: {'id_token': firebaseIdToken},
    );
    _sessionToken = response.data?['session_token'] as String?;
    if (_sessionToken == null) {
      throw const FormatException('Backend session token was not returned.');
    }
  }

  Future<List<ProjectRecord>> fetchProjects() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/projects',
      options: Options(headers: _sessionHeaders),
    );
    final projects = response.data?['projects'] as List<dynamic>? ?? const [];
    return projects
        .map((project) =>
            ProjectRecord.fromJson(project as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserRecord>> fetchUsers() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/users',
      options: Options(headers: _sessionHeaders),
    );
    final users = response.data?['users'] as List<dynamic>? ?? const [];
    return users
        .map((user) => UserRecord.fromJson(user as Map<String, dynamic>))
        .toList();
  }

  Future<InvitationRecord> createInvitation({
    required String email,
    required String role,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/users/invitations',
      data: {'email': email, 'role': role},
      options: Options(headers: _sessionHeaders),
    );
    return InvitationRecord.fromJson(response.data!);
  }

  Future<InvitationRecord> validateInvitation(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/users/invitations/$token',
    );
    return InvitationRecord.fromJson(response.data!);
  }

  Future<void> registerFromInvitation({
    required String token,
    required String idToken,
    required String firstName,
    required String lastName,
  }) async {
    await _dio.post<void>(
      '/auth/invitations/register',
      data: {
        'token': token,
        'id_token': idToken,
        'first_name': firstName,
        'last_name': lastName,
      },
    );
  }

  Future<SearchResponseRecord> searchProject({
    required String projectId,
    required String query,
    int limit = 10,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/projects/$projectId/search',
      data: {'query': query, 'limit': limit},
      options: Options(headers: _sessionHeaders),
    );
    return SearchResponseRecord.fromJson(response.data ?? const {});
  }

  Future<ProjectRecord> fetchProject(String projectId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/projects/$projectId',
      options: Options(headers: _sessionHeaders),
    );
    return ProjectRecord.fromJson(response.data!);
  }

  Future<ProjectRecord> createProject({
    required String name,
    required String description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/projects',
      data: {'name': name, 'description': description},
      options: Options(headers: _sessionHeaders),
    );
    return ProjectRecord.fromJson(response.data!);
  }

  Future<List<DocumentRecord>> fetchDocuments(String projectId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/projects/$projectId/documents',
      options: Options(headers: _sessionHeaders),
    );
    final documents = response.data?['documents'] as List<dynamic>? ?? const [];
    return documents
        .map((document) =>
            DocumentRecord.fromJson(document as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteDocument({
    required String projectId,
    required String documentId,
  }) async {
    await _dio.delete<void>(
      '/projects/$projectId/documents/$documentId',
      options: Options(headers: _sessionHeaders),
    );
  }

  Future<DocumentRecord> uploadDocument({
    required String projectId,
    required PlatformFile file,
  }) async {
    final multipart = file.bytes != null
        ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
        : file.path == null
            ? null
            : await MultipartFile.fromFile(file.path!, filename: file.name);
    if (multipart == null) {
      throw const FormatException('Selected file is not readable.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/projects/$projectId/documents',
      data: FormData.fromMap({'file': multipart}),
      options: Options(headers: _sessionHeaders),
    );
    return DocumentRecord.fromJson(response.data!);
  }

  Map<String, String> get _sessionHeaders => _sessionToken == null
      ? const <String, String>{}
      : {'Authorization': 'Bearer $_sessionToken'};
}
