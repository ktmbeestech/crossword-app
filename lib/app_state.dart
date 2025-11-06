import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // Add any app-wide state that needs to be reset on logout
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;
  
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  Future<void> resetState() async {
    _isLoading = false;
    // Add any other state that needs to be reset
    notifyListeners();
  }
}
