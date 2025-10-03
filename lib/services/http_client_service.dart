import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// HTTP client service with automatic token refresh capabilities
class HttpClientService {
  static HttpClientService? _instance;
  static HttpClientService get instance {
    _instance ??= HttpClientService._internal();
    return _instance!;
  }

  late Dio _dio;
  AuthService? _authService;

  HttpClientService._internal() {
    _initializeDio();
  }

  /// Initialize Dio with interceptors
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add token refresh interceptor
    _dio.interceptors.add(TokenRefreshInterceptor(this));
    
    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint('[HTTP] $object'),
      ));
    }
  }

  /// Set the auth service instance for token management
  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  /// Get the Dio instance
  Dio get dio => _dio;

  /// Make a GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Interceptor that handles token refresh automatically
class TokenRefreshInterceptor extends Interceptor {
  final HttpClientService _httpClientService;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  TokenRefreshInterceptor(this._httpClientService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add authorization header if we have a token
    final authService = _httpClientService._authService;
    if (authService != null && authService.isAuthenticated) {
      final accessToken = authService.accessToken;
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    
    debugPrint('[HTTP] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      debugPrint('[HTTP] Received 401, attempting token refresh...');
      
      // If we're already refreshing, queue this request
      if (_isRefreshing) {
        _pendingRequests.add(err.requestOptions);
        debugPrint('[HTTP] Queuing request while refresh in progress...');
        return;
      }

      _isRefreshing = true;

      try {
        final authService = _httpClientService._authService;
        if (authService != null && authService.isAuthenticated) {
          // Attempt to refresh the token
          await authService.refreshTokenIfNeeded();
          
          // Check if we still have a valid token after refresh
          if (authService.isAuthenticated) {
            final newToken = authService.accessToken;
            if (newToken != null) {
              // Update the original request with new token
              err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              
              // Retry the original request
              debugPrint('[HTTP] Retrying original request with new token...');
              final response = await _httpClientService.dio.fetch(err.requestOptions);
              handler.resolve(response);
              
              // Process any pending requests
              await _processPendingRequests(newToken);
              return;
            }
          }
        }
        
        // If refresh failed, clear auth state and redirect to login
        debugPrint('[HTTP] Token refresh failed, clearing auth state...');
        if (authService != null) {
          await authService.logout();
        }
        
      } catch (e) {
        debugPrint('[HTTP] Error during token refresh: $e');
        // Clear auth state on any error
        final authService = _httpClientService._authService;
        if (authService != null) {
          await authService.logout();
        }
      } finally {
        _isRefreshing = false;
        _pendingRequests.clear();
      }
    }
    
    // For non-401 errors or if refresh failed, pass through the error
    handler.next(err);
  }

  /// Process pending requests with the new token
  Future<void> _processPendingRequests(String newToken) async {
    debugPrint('[HTTP] Processing ${_pendingRequests.length} pending requests...');
    
    for (final requestOptions in _pendingRequests) {
      try {
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        await _httpClientService.dio.fetch(requestOptions);
        debugPrint('[HTTP] Successfully processed pending request: ${requestOptions.method} ${requestOptions.path}');
      } catch (e) {
        debugPrint('[HTTP] Failed to process pending request: $e');
      }
    }
    
    _pendingRequests.clear();
  }
}
