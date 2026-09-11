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
        .map((project) => ProjectRecord.fromJson(project as Map<String, dynamic>))
        .toList();
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
        .map((document) => DocumentRecord.fromJson(document as Map<String, dynamic>))
        .toList();
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