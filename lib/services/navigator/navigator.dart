import 'package:flutter/material.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static BuildContext? get currentContext => navigatorKey.currentContext;
  
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool rootNavigator = false,
  }) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }
  
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
    bool rootNavigator = false,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }
  
  static void popUntilFirst() {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }
  
  static void pop<T extends Object?>([T? result]) {
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop<T>(result);
    }
  }
  
  static Future<bool> maybePop<T extends Object?>([T? result]) async {
    return await navigatorKey.currentState!.maybePop<T>(result);
  }
  
  static Future<Object?> pushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
    bool rootNavigator = false,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      newRouteName,
      predicate,
      arguments: arguments,
    );
  }
}

// For backward compatibility
final navigatorKey = AppNavigator.navigatorKey;