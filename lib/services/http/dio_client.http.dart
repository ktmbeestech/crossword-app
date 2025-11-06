import 'package:dio/dio.dart';
import '../../constant/api/api.url.constant.dart';
import 'interceptor.dart';

class ApiClient {
  static ApiClient? _instance;
  final Dio _dio;

  ApiClient._internal({required Dio dio}) : _dio = dio {
    _dio.options = BaseOptions(
      baseUrl: ApiUrl.baseURL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: false,
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );

    _dio.interceptors.add(CustomInterceptor(_dio));
  }

  Dio getDio() => _dio;

  static ApiClient get instance {
    _instance ??= ApiClient._internal(dio: Dio());
    return _instance!;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // Forward the options (so headers / validateStatus etc. are applied)
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    try {
      if (data != null) {
        return await _dio.post(
          path,
          queryParameters: queryParameters,
          data: data,
          options: options,
        );
      } else {
        return await _dio.post(
          path,
          queryParameters: queryParameters,
          options: options,
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> postFormData(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    try {
      if (data != null) {
        return await _dio.post(
          path,
          queryParameters: queryParameters,
          data: FormData.fromMap(data),
          options: options,
        );
      } else {
        return await _dio.post(
          path,
          queryParameters: queryParameters,
          options: options,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 303) {
        rethrow;
      }
      if (e.response != null) {
        throw e.response!.data['message'];
      }
      throw e.message ?? "Something went wrong";
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        queryParameters: queryParameters,
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response!.data['message'];
      }
      throw e.message ?? "Something went wrong";
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _dio.put(path, queryParameters: queryParameters, data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response!.data['message'];
      }
      throw e.message ?? "Something went wrong";
    } catch (e) {
      rethrow;
    }
  }
}

ApiClient get apiClient => ApiClient.instance;
