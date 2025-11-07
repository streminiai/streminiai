// lib/features/keyboard_provider.dart
import 'package:flutter/foundation.dart';
import 'package:stremini_chatbot/models/keyboard_action.dart'; // Assuming this model exists
import 'package:stremini_chatbot/services/stremini_api_service.dart';

enum KeyboardStatus { idle, processing, complete, error }

class KeyboardProvider with ChangeNotifier {
  final StreminiApiService _apiService;
  
  KeyboardStatus _status = KeyboardStatus.idle;
  String _modifiedText = '';
  String? _errorMessage;

  // Constructor
  KeyboardProvider({required StreminiApiService apiService}) : _apiService = apiService;

  // Getters
  KeyboardStatus get status => _status;
  String get modifiedText => _modifiedText;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _status == KeyboardStatus.processing;

  /// Performs text completion based on the current input.
  Future<void> completeText(String currentText) async {
    await _performAction(
      actionType: KeyboardActionType.complete,
      text: currentText,
      apiCall: (text) => _apiService.completeText(text),
    );
  }

  /// Changes the tone of the provided text.
  Future<void> changeTone(String text, String newTone) async {
    await _performAction(
      actionType: KeyboardActionType.tone,
      text: text,
      apiCall: (text) => _apiService.changeTextTone(text, newTone),
    );
  }

  /// Translates the provided text.
  Future<void> translateText(String text, String targetLang) async {
    await _performAction(
      actionType: KeyboardActionType.translate,
      text: text,
      apiCall: (text) => _apiService.translateKeyboardText(text, targetLang),
    );
  }

  /// Generic handler for all keyboard actions.
  Future<void> _performAction({
    required KeyboardActionType actionType,
    required String text,
    required Future<String> Function(String) apiCall,
  }) async {
    if (text.trim().isEmpty || isProcessing) return;
    
    _setStatus(KeyboardStatus.processing);
    _modifiedText = '';
    _errorMessage = null;

    try {
      final result = await apiCall(text);
      _modifiedText = result;
      _setStatus(KeyboardStatus.complete);
      
      // The calling widget will typically use _modifiedText to replace the input field content.
      
    } catch (e) {
      _errorMessage = 'Action failed: ${actionType.name} - ${e.toString()}';
      _modifiedText = '';
      _setStatus(KeyboardStatus.error);
    }
  }

  /// Resets the modified text result.
  void clearResult() {
    _modifiedText = '';
    _errorMessage = null;
    _setStatus(KeyboardStatus.idle);
  }
  
  // --- Internal Helpers ---
  void _setStatus(KeyboardStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}

// Assuming the model definition for KeyboardActionType is needed here or in a separate file:
enum KeyboardActionType { complete, tone, translate }

// If KeyboardAction model is separate, ensure it exists in lib/models/
// For this context, we will rely on the string result.
