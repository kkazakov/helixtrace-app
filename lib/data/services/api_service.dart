import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  late final Dio _dio;
  final String baseUrl;

  ApiService({String? customBaseUrl})
      : baseUrl = customBaseUrl ?? dotenv.env['BASE_URL'] ?? 'https://trace-api.meshcore.bg/' {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  Future<Response> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/login',
        data: {'email': email, 'password': password},
      );
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw ApiException('Account is disabled. Contact support.', 403);
      }
      if (e.response?.statusCode == 401) {
        throw ApiException('Invalid email or password.', 401);
      }
      throw ApiException(e.message ?? 'Login failed', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/register',
        data: {'email': email, 'password': password},
      );
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw ApiException('An account with this email already exists.', 409);
      }
      if (e.response?.statusCode == 400) {
        throw ApiException('Registration failed. Check your input.', 400);
      }
      throw ApiException(e.message ?? 'Registration failed', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> getProfile({required String token}) async {
    try {
      final response = await _dio.get(
        '/api/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Failed to fetch profile', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> getTracePath({
    required String token,
    required String from,
    required String to,
  }) async {
    try {
      final response = await _dio.get(
        '/api/trace-path',
        queryParameters: {
          'from': from,
          'to': to,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Failed to fetch trace path', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> getPoints({
    required String token,
    bool includePublic = false,
    bool includeMeshcoreDashboard = false,
  }) async {
    try {
      final response = await _dio.get(
        '/api/points',
        queryParameters: {
          'include_public': includePublic,
          'include_meshcore_dashboard': includeMeshcoreDashboard,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Failed to fetch points', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> createPoint({
    required String token,
    required double lat,
    required double lon,
    required int categoryId,
    bool public = false,
    String? label,
  }) async {
    try {
      final data = <String, dynamic>{
        'lat': lat,
        'lon': lon,
        'category_id': categoryId,
        'public': public,
      };
      if (label != null) {
        data['label'] = label;
      }

      final response = await _dio.post(
        '/api/point',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Failed to create point', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> getPoint({required String token, required String id}) async {
    try {
      final response = await _dio.get(
        '/api/point/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Failed to fetch point', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> updatePoint({
    required String token,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.put(
        '/api/point/$id',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Failed to update point', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> deletePoint({required String token, required String id}) async {
    try {
      final response = await _dio.delete(
        '/api/point/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Failed to delete point', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> getPointInfo({
    required String token,
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _dio.get(
        '/api/point/info',
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Failed to fetch elevation', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> getPointCategories({required String token}) async {
    try {
      final response = await _dio.get(
        '/api/point-categories',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Failed to fetch categories', e.response?.statusCode ?? 500);
    }
  }

  Future<Response> healthCheck() async {
    try {
      final response = await _dio.get('/api/health');
      return response;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Health check failed', e.response?.statusCode ?? 500);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
