import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

import 'base_interceptor.dart';

class RetryOnErrorInterceptor extends BaseInterceptor {
  RetryOnErrorInterceptor(this.dio);

  final Dio dio;

  static const _retryHeaderKey = 'isRetry';
  static const _retryCountKey = 'retryCount';

  @override
  int get priority => BaseInterceptor.retryOnErrorPriority;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.headers.containsKey(_retryHeaderKey)) {
      options.headers[_retryCountKey] = RetryOnErrorConstants.maxRetries;
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    assert(err.requestOptions.headers[_retryCountKey] != null);
    final retryCount = err.requestOptions.headers[_retryCountKey] as int;
    if (retryCount > 0 && _shouldRetry(err)) {
      await Future<void>.delayed(RetryOnErrorConstants.retryInterval);
      try {
        final response = await dio.fetch<dynamic>(
          err.requestOptions
            ..headers[_retryHeaderKey] = true
            ..headers[_retryCountKey] = retryCount - 1,
        );

        return handler.resolve(response);
      } catch (_) {
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioError error) =>
      error.type != DioErrorType.cancel && error.type != DioErrorType.response;
}
