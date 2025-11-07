import 'package:flutter/foundation.dart';
import '../services/stremini_api_service.dart';

class TranslationProvider with ChangeNotifier {
  final StreminiApiService _apiService;
  
  bool _isTranslating = false;
  String? _error;
  Map<String, String>? _translatedContent;

  TranslationProvider(this._apiService);

  bool get isTranslating => _isTranslating;
  String? get error => _error;
  Map<String, String>? get translatedContent => _translatedContent;

  Future<void> translateScreen(
    List<Map<String, String>> elements,
    String targetLanguage,
  ) async {
    _isTranslating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.translateScreen(
        elements,
        targetLanguage,
      );
      _translatedContent = Map<String, String>.from(result['translations']);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  void clearTranslations() {
    _translatedContent = null;
    _error = null;
    notifyListeners();
  }
}
