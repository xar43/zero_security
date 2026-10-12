import 'dart:convert' show JsonEncoder;
import 'dart:developer' show log;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/constants/url_constants.dart';
import '../local/local_storage_services.dart';

class ApiServices {
  final Dio _dio;

  ApiServices()
    : _dio = Dio(
        BaseOptions(
          baseUrl: UrlConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      ) {
    _addInterceptors();
  }

  void _addInterceptors() {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          final token = LocalStorageServices.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.data is FormData) {
            _logRequest(options.method, options.uri.toString(), body: {}, headers: options.headers);
          } else {
            _logRequest(options.method, options.uri.toString(), body: options.data, headers: options.headers);
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response.requestOptions.method, response.requestOptions.uri.toString(), response);
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          _logError(error.type.name, error.requestOptions.uri.toString(), error, error.stackTrace);
          return handler.next(error);
        },
      ),
    );
  }

  // ==================== Core Methods ====================
  Future<Map<String, dynamic>?> getRequest(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> deleteRequest(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> postRequest(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> postMultipartFormData(
    String path, {
    required Map<String, dynamic> fields,
    List<MapEntry<String, MultipartFile>>? files,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      // Create FormData
      final formData = FormData();

      // Add regular fields
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      // Add files if any
      if (files != null) {
        for (final fileEntry in files) {
          formData.files.add(fileEntry);
        }
      }

      // Prepare headers
      final Map<String, String> finalHeaders = {...headers ?? {}};

      final response = await _dio.post(
        path,
        data: formData,
        queryParameters: queryParams,
        options: Options(headers: finalHeaders),
        onSendProgress: onSendProgress,
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> putRequest(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: body,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> patchRequest(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: body,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
  }

  dynamic _handleError(DioException error) {
    String message = "An error occurred";

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = "Connection timeout";
        break;
      case DioExceptionType.receiveTimeout:
        message = "Receive timeout";
        break;
      case DioExceptionType.badResponse:
        message = _parseBadResponse(error.response);
        break;
      case DioExceptionType.cancel:
        message = "Request cancelled";
        break;
      case DioExceptionType.connectionError:
        message = "Connection error";
        break;
      case DioExceptionType.sendTimeout:
        message = "Send timeout";
        break;
      case DioExceptionType.unknown:
        message = "Unknown error";
        break;
      default:
        message = error.message ?? "Unknown error";
    }

    throw message;
  }

  String _parseBadResponse(Response? response) {
    if (response == null) return "Server error";

    final message = response.data is String
        ? response.data
        : (response.data['message'] ??
              response.data['error'] ??
              (response.data['promotionId'] != null
                  ? "Promotion can't be applied to this items. Please select valid items."
                  : "Error: ${response.statusCode}"));

    return message.toString();
  }

  final String _logDivider = "------------------------------------------";

  // ==================== Logging ====================
  void _logRequest(String method, String url, {Map<String, dynamic>? body, Map<String, dynamic>? headers}) {
    if (!kIsWeb) {
      final buffer = StringBuffer();
      buffer.writeln('$_logDivider API $method REQUEST $_logDivider');
      buffer.writeln('URL: $url');
      buffer.writeln('HEADERS: ${headers.toString()}');

      if (body != null) {
        buffer.writeln('BODY: ${_prettyJson(body)}');
      }

      buffer.writeln(_logDivider);
      log(buffer.toString());
    }
  }

  void _logResponse(String method, String url, Response response) {
    // final buffer = StringBuffer();
    // buffer.writeln('$_logDivider API $method RESPONSE $_logDivider');
    // buffer.writeln('URL: $url');
    // buffer.writeln('STATUS: ${response.statusCode}');

    // final dynamic responseBody = response.data;

    // if (response.statusCode == 200) {
    //   if (responseBody != null) {
    //     buffer.writeln('RESPONSE: $responseBody');
    //   } else {
    //     buffer.writeln('RESPONSE BODY: ${response.data}');
    //   }
    // }

    // buffer.writeln(_logDivider);
    // log(buffer.toString());
  }

  void _logError(String method, String url, dynamic error, StackTrace? stackTrace) {
    if (!kIsWeb) {
      final buffer = StringBuffer();
      buffer.writeln('$_logDivider API $method ERROR $_logDivider');
      buffer.writeln('URL: $url');
      buffer.writeln('ERROR: $error');

      if (stackTrace != null) {
        buffer.writeln('STACK TRACE: $stackTrace');
      }

      buffer.writeln(_logDivider);
      log(buffer.toString());
    }
  }

  String _prettyJson(dynamic json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
