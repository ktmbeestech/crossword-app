import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../local_storage/local_storage.services.dart';
import '../navigator/navigator.dart';

class CustomInterceptor extends Interceptor {
  final Dio dio;
  // Guards to prevent multiple duplicate snackbars and repeated navigation
  bool _isSessionExpiredHandled = false;
  bool _navigatedToLogin = false;

  CustomInterceptor(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Explicit skip list for endpoints that should not have Authorization
    final skipAuthPaths = [
      '/auth/verify',
      '/auth/login',
      '/auth/signup',
      '/auth/refresh',
      '/login',
    ];

    if (!skipAuthPaths.any((p) => options.path.contains(p))) {
      try {
        final accessToken = await storageInstance.getData(key: 'accessToken');
        final hasToken = accessToken != null && accessToken.isNotEmpty;
        debugPrint(
          "Using token for ${options.path}: ${hasToken ? 'Token exists' : 'No token'}",
        );

        if (hasToken) {
          // Normalize token so we don't double-prefix 'Bearer '
          final normalized =
              accessToken!.startsWith('Bearer ')
                  ? accessToken
                  : 'Bearer $accessToken';

          // Mask token for logs (do not expose full token in logs)
          final masked =
              accessToken.length > 10
                  ? '${accessToken.substring(0, 6)}...${accessToken.substring(accessToken.length - 4)}'
                  : accessToken;

          options.headers['Authorization'] = normalized;
          debugPrint(
            'Authorization header set for ${options.path}, token: $masked',
          );
          // Log final headers (mask sensitive values)
          try {
            final headersCopy = Map<String, dynamic>.from(options.headers);
            if (headersCopy.containsKey('Authorization')) {
              final v = headersCopy['Authorization'] as String;
              headersCopy['Authorization'] =
                  v.length > 10
                      ? '${v.substring(0, 6)}...${v.substring(v.length - 4)}'
                      : v;
            }
            if (headersCopy.containsKey('X-Barrier-Token')) {
              final v = headersCopy['X-Barrier-Token'] as String;
              headersCopy['X-Barrier-Token'] =
                  v.length > 10
                      ? '${v.substring(0, 6)}...${v.substring(v.length - 4)}'
                      : v;
            }
            debugPrint(
              'Final request headers for ${options.path}: $headersCopy',
            );
          } catch (_) {}
        } else {
          debugPrint('No token available for ${options.path}');
        }
      } catch (e) {
        debugPrint('Error getting token for request: $e');
      }
    } else {
      debugPrint('Skipping token check for ${options.path}');
    }

    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.data != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('accessToken')) {
        await storageInstance.saveToken(data['accessToken']);
      }
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    debugPrint('Interceptor error: ${err.message}');
    debugPrint('Status code: ${err.response?.statusCode}');
    debugPrint('Request path: ${err.requestOptions.path}');

    // Skip handling for login/verify endpoints
    if (err.requestOptions.path.contains('/auth/verify') ||
        err.requestOptions.path.contains('/login')) {
      debugPrint('Skipping error handling for auth endpoint');
      return handler.next(err);
    }

    // Handle token expiration (401 Unauthorized)
    if (err.response?.statusCode == 401) {
      debugPrint('Received 401 Unauthorized, handling token expiration');
      await _handleTokenExpiration(err, handler);
      return;
    }

    // Handle connection errors
    if (err.type == DioExceptionType.connectionError &&
        err.error is SocketException) {
      return handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: 'No Internet Connection',
          message: "No Internet Connection",
          type: DioExceptionType.connectionError,
        ),
      );
    }

    // Handle timeout errors
    if (err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionTimeout) {
      return handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: 'Please try again',
          message: "Please try again",
          type: DioExceptionType.sendTimeout,
        ),
      );
    }

    return handler.next(err);
  }

  /// Handles token expiration by clearing user data and navigating to login
  Future<void> _handleTokenExpiration(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    debugPrint('Handling token expiration...');

    // Ensure we don't have multiple token expiration handlers running
    if (_isSessionExpiredHandled) {
      debugPrint('Token expiration already being handled, skipping');
      return handler.next(err);
    }

    _isSessionExpiredHandled = true;

    try {
      // Clear any existing dialogs
      final context = AppNavigator.navigatorKey.currentContext;
      if (context != null) {
        try {
          Navigator.of(
            context,
            rootNavigator: true,
          ).popUntil((route) => route.isFirst);
        } catch (e) {
          debugPrint('Error clearing dialogs: $e');
        }
      }

      // Clear all user data
      await _clearAllUserData();

      // Reset app state if using Provider
      if (AppNavigator.navigatorKey.currentContext != null) {
        try {
          final appState =
              AppNavigator.navigatorKey.currentContext!.read<AppState>();
          await appState.resetState();
        } catch (e) {
          debugPrint('Error resetting app state: $e');
        }
      }

      // Show session expired message
      _showSessionExpiredMessage();

      // Add a small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to login page
      await _navigateToLogin();
    } catch (e) {
      debugPrint('Error in _handleTokenExpiration: $e');
    } finally {
      _isSessionExpiredHandled = false;
    }

    return handler.next(err);
  }

  /// Clears all user-related data from local storage
  Future<void> _clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all stored keys (customize this list based on your app)
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.remove('userName');
      await prefs.remove('userProfile');
      await prefs.remove('isLoggedIn');
      await prefs.remove('lastLoginTime');
      await prefs.remove('userRole');
      await prefs.remove('userPermissions');
      await storageInstance.clearAll();
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  /// Shows session expired message to user
  void _showSessionExpiredMessage() {
    // Use the global navigator key to show snackbar
    final context = AppNavigator.navigatorKey.currentContext;
    if (context != null) {
      final messenger = ScaffoldMessenger.of(context);
      // Ensure any existing snackbars are dismissed before showing a new one
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Session expired. Please login again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              messenger.hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Navigates to login page and clears navigation stack
  Future<void> _navigateToLogin() async {
    if (_navigatedToLogin) {
      debugPrint('Already navigated to login, skipping');
      return;
    }

    _navigatedToLogin = true;
    debugPrint('Preparing to navigate to login screen');

    try {
      // Ensure any dialogs are dismissed
      final context = AppNavigator.navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
      }

      // Add a small delay to ensure any pending operations complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Use the enhanced navigation service
      await AppNavigator.pushNamedAndRemoveUntil('/login', (route) => false);

      debugPrint('Successfully navigated to login');
    } catch (e, stackTrace) {
      debugPrint('Error navigating to login: $e');
      debugPrint('Stack trace: $stackTrace');
      // Reset the flag to allow retry
      _navigatedToLogin = false;

      // Try again after a delay if navigation failed
      await Future.delayed(const Duration(seconds: 1));
      if (!_navigatedToLogin) {
        await _navigateToLogin();
      }
    }
  }
}
