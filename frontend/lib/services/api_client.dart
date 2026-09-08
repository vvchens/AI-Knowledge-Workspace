import 'package:dio/dio.dart';

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

class ApiClient {
  ApiClient._() : _dio = Dio(BaseOptions(baseUrl: AppEnvironment.apiBaseUrl));

  static final ApiClient instance = ApiClient._();

  final Dio _dio;
  String? _sessionToken;

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

  Map<String, String> get _sessionHeaders => _sessionToken == null
      ? const <String, String>{}
      : {'Authorization': 'Bearer $_sessionToken'};
}