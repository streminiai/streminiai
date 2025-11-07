// lib/features/automation_provider.dart
import 'package:flutter/foundation.dart';
import 'package:stremini_chatbot/models/automation_action.dart';
import 'package:stremini_chatbot/services/stremini_api_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum AutomationStatus { idle, listening, processing, success, error }

class AutomationProvider with ChangeNotifier {
  final StreminiApiService _apiService;
  final stt.SpeechToText _speech = stt.SpeechToText();

  AutomationStatus _status = AutomationStatus.idle;
  String _lastSpokenText = '';
  AutomationAction? _lastAction;
  String? _errorMessage;

  // Constructor
  AutomationProvider({required StreminiApiService apiService}) : _apiService = apiService;

  // Getters
  AutomationStatus get status => _status;
  String get lastSpokenText => _lastSpokenText;
  AutomationAction? get lastAction => _lastAction;
  String? get errorMessage => _errorMessage;
  bool get isListening => _status == AutomationStatus.listening;

  /// Starts listening for a voice command.
  Future<void> startListening() async {
    if (_status == AutomationStatus.listening) return;

    bool available = await _speech.initialize(
      onStatus: (val) => _onSpeechStatus(val),
      onError: (val) => _onSpeechError(val),
    );

    if (available) {
      _setStatus(AutomationStatus.listening);
      _lastSpokenText = '';
      _lastAction = null;
      notifyListeners();

      // Start listening. The result handler will call _processVoiceCommand.
      await _speech.listen(
        onResult: (val) {
          _lastSpokenText = val.recognizedWords;
          notifyListeners();
          if (val.finalResult) {
            // Processing will begin when final result is available
            _processVoiceCommand(val.recognizedWords);
          }
        },
      );
    } else {
      _errorMessage = 'Speech recognition is not available.';
      _setStatus(AutomationStatus.error);
    }
  }

  /// Stops listening if active.
  void stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
    if (_status == AutomationStatus.listening) {
      // If stopped manually before final result, reset to idle
      _setStatus(AutomationStatus.idle); 
    }
  }

  /// Sends the recognized text to the backend for action parsing.
  Future<void> _processVoiceCommand(String command) async {
    if (command.trim().isEmpty) {
      _errorMessage = 'No voice command was recognized.';
      _setStatus(AutomationStatus.error);
      return;
    }
    
    _setStatus(AutomationStatus.processing);

    try {
      final action = await _apiService.parseVoiceCommand(command);
      _lastAction = action;
      _errorMessage = null;
      _setStatus(AutomationStatus.success);
      
      // In a real app, you would execute the action here:
      // if (action.type == 'open_app') { /* launch app */ }
      // else if (action.type == 'settings') { /* navigate to settings */ }

      // Reset to idle after a brief success display
      Future.delayed(const Duration(seconds: 3), () {
        if (_status == AutomationStatus.success) {
          _setStatus(AutomationStatus.idle);
        }
      });
      
    } catch (e) {
      _errorMessage = 'Failed to process command: ${e.toString()}';
      _lastAction = null;
      _setStatus(AutomationStatus.error);
    }
  }

  // --- Internal Helpers ---
  void _setStatus(AutomationStatus newStatus) {
    _status = newStatus;
    if (newStatus == AutomationStatus.idle || newStatus == AutomationStatus.listening) {
      _errorMessage = null;
    }
    notifyListeners();
  }
  
  void _onSpeechStatus(String status) {
    debugPrint('Speech Status: $status');
  }

  void _onSpeechError(stt.SpeechRecognitionError error) {
    debugPrint('Speech Error: ${error.errorMsg}');
    _errorMessage = 'Voice recognition error: ${error.errorMsg}';
    _setStatus(AutomationStatus.error);
  }
}
