import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../exceptions/api_exceptions.dart';

class ApiService {
  late final Dio _dio;
  int? _userId;  // Make it nullable and mutable

  ApiService({int? userId}) : _userId = userId {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_errorInterceptor());
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
  }

  // Update userId when user logs in
  void updateUserId(int userId) {
    _userId = userId;
  }

  // Expose Dio instance for advanced use cases (e.g., custom headers)
  Dio get dio => _dio;

  // Auth Interceptor - Add X-User-Id header
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Only add X-User-Id if we have a userId (for non-auth endpoints)
        if (_userId != null) {
          options.headers['X-User-Id'] = _userId.toString();
        }
        return handler.next(options);
      },
    );
  }

  // Error Interceptor - Handle backend errors
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response != null) {
          final statusCode = error.response!.statusCode;
          final data = error.response!.data;

          // Parse error response {code, message, timestamp, path}
          String? errorCode;
          String? errorMessage;

          if (data is Map<String, dynamic>) {
            errorCode = data['code'] as String?;
            errorMessage = data['message'] as String?;
          }

          // Handle specific error codes
          switch (statusCode) {
            case 409: // Optimistic Locking Failure
              if (errorCode == AppConstants.concurrencyErrorCode) {
                return handler.reject(
                  DioException(
                    requestOptions: error.requestOptions,
                    error: ConcurrencyException(errorMessage ?? 'Concurrency error'),
                    type: DioExceptionType.badResponse,
                  ),
                );
              }
              break;

            case 400: // Bad Request
              if (errorCode == AppConstants.insufficientFundsCode) {
                return handler.reject(
                  DioException(
                    requestOptions: error.requestOptions,
                    error: InsufficientFundsException(message: errorMessage ?? ''),
                    type: DioExceptionType.badResponse,
                  ),
                );
              } else if (errorCode == AppConstants.invalidBidCode) {
                return handler.reject(
                  DioException(
                    requestOptions: error.requestOptions,
                    error: InvalidBidException(message: errorMessage ?? ''),
                    type: DioExceptionType.badResponse,
                  ),
                );
              }
              break;

            case 404: // Not Found
              if (errorCode == AppConstants.auctionNotFoundCode) {
                return handler.reject(
                  DioException(
                    requestOptions: error.requestOptions,
                    error: AuctionNotFoundException(errorMessage ?? 'Auction not found'),
                    type: DioExceptionType.badResponse,
                  ),
                );
              }
              break;
          }

          // Generic API error
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: ApiException(
                errorMessage ?? 'Unknown error occurred',
                statusCode,
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        }

        // Network error
        return handler.next(error);
      },
    );
  }

  // Logging Interceptor
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('➡️ ${options.method} ${options.uri}');
        print('Headers: ${options.headers}');
        if (options.data != null) {
          print('Body: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('⬅️ ${response.statusCode} ${response.requestOptions.uri}');
        print('Data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error: ${error.message}');
        if (error.response != null) {
          print('Status: ${error.response!.statusCode}');
          print('Data: ${error.response!.data}');
        }
        return handler.next(error);
      },
    );
  }

  // Generic HTTP Methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  // Auction API Methods
  Future<List<dynamic>> getActiveAuctions() async {
    final response = await get(AppConstants.auctionsEndpoint);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAuctionById(int id) async {
    final response = await get('${AppConstants.auctionsEndpoint}/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAuctionBids(int auctionId) async {
    final response = await get('${AppConstants.auctionsEndpoint}/$auctionId/bids');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> placeBid({
    required int auctionId,
    required double amount,
  }) async {
    final response = await post(
      AppConstants.bidsEndpoint,
      data: {
        'auctionId': auctionId,
        'amount': amount,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // Wallet API Methods
  Future<Map<String, dynamic>> getWallet(int userId) async {
    final response = await get('${AppConstants.walletsEndpoint}/$userId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> depositFunds({
    required int userId,
    required double amount,
  }) async {
    final response = await post(
      '${AppConstants.walletsEndpoint}/deposit',
      data: {
        'userId': userId,
        'amount': amount,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
