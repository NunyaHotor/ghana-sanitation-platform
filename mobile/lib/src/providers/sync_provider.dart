import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  SyncProvider() {
    _initializeConnectivity();
  }

  void _initializeConnectivity() {
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
  }

  void setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
    return _isOnline;
  }
}
