// lib/features/security_provider.dart
import 'package:flutter/foundation.dart';
import 'package:stremini_chatbot/models/security_scan_result.dart';
import 'package:stremini_chatbot/services/stremini_api_service.dart';

enum SecurityStatus { idle, scanning, checkingUrl, complete, error }

class SecurityProvider with ChangeNotifier {
  final StreminiApiService _apiService;
  
  SecurityStatus _status = SecurityStatus.idle;
  SecurityScanResult? _lastScanResult;
  String? _errorMessage;

  // Constructor
  SecurityProvider({required StreminiApiService apiService}) : _apiService = apiService;

  // Getters
  SecurityStatus get status => _status;
  SecurityScanResult? get lastScanResult => _lastScanResult;
  String? get errorMessage => _errorMessage;
  bool get isScanning => _status == SecurityStatus.scanning || _status == SecurityStatus.checkingUrl;

  /// Scans generic text content for threats or suspicious links.
  Future<void> scanContent(String content) async {
    if (content.trim().isEmpty || isScanning) return;
    
    _setStatus(SecurityStatus.scanning);
    _lastScanResult = null;

    try {
      final result = await _apiService.scanContent(content);
      _lastScanResult = result;
      _errorMessage = null;
      _setStatus(SecurityStatus.complete);
      
    } catch (e) {
      _errorMessage = 'Content scan failed: ${e.toString()}';
      _lastScanResult = null;
      _setStatus(SecurityStatus.error);
    }
  }

  /// Checks a specific URL for safety.
  Future<void> checkUrl(String url) async {
    if (url.trim().isEmpty || isScanning) return;

    // Basic URL validation
    if (!Uri.tryParse(url)?.hasAuthority ?? true) {
        _errorMessage = 'Invalid URL format.';
        _setStatus(SecurityStatus.error);
        return;
    }
    
    _setStatus(SecurityStatus.checkingUrl);
    _lastScanResult = null;

    try {
      final result = await _apiService.checkUrl(url);
      _lastScanResult = result;
      _errorMessage = null;
      _setStatus(SecurityStatus.complete);
      
    } catch (e) {
      _errorMessage = 'URL check failed: ${e.toString()}';
      _lastScanResult = null;
      _setStatus(SecurityStatus.error);
    }
  }

  /// Resets the scan results.
  void clearScan() {
    _lastScanResult = null;
    _errorMessage = null;
    _setStatus(SecurityStatus.idle);
  }
  
  // --- Internal Helpers ---
  void _setStatus(SecurityStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}
