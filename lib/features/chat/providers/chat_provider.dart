// lib/features/chat_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stremini_chatbot/models/chat_message.dart';
import 'package:stremini_chatbot/services/stremini_api_service.dart';

enum ChatStatus { idle, loading, streaming, error }

class ChatProvider with ChangeNotifier {
  final StreminiApiService _apiService;
  final List<ChatMessage> _messages = [
    // Initial welcome message (based on floating ui.jpg & project structure)
    ChatMessage(
      text: "Hey there! I'm Stremini - your AI assistant & digital bodyguard. I can help with chat, translation, security, and more.",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  ChatStatus _status = ChatStatus.idle;
  String? _errorMessage;

  // Constructor
  ChatProvider({required StreminiApiService apiService}) : _apiService = apiService;

  // Getters
  List<ChatMessage> get messages => _messages;
  ChatStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isStreaming => _status == ChatStatus.streaming;

  // --- Core Methods ---

  /// Sends a user message and initiates the AI response stream.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _status == ChatStatus.streaming) return;

    // 1. Add user message
    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // 2. Prepare for AI response (Add a placeholder message)
    final aiPlaceholderMessage = ChatMessage(
      text: '', // Start with empty text
      isUser: false,
      timestamp: DateTime.now(),
    );
    _addMessage(aiPlaceholderMessage);
    
    _setStatus(ChatStatus.streaming);
    String fullResponse = '';

    try {
      // 3. Call the streaming API
      Stream<String> responseStream = _apiService.streamChatMessage(text);
      
      await for (final chunk in responseStream) {
        // Update the last message (the placeholder) with the new chunk
        fullResponse += chunk;
        
        // This is a common pattern to update the last message in a stream
        _messages.last = aiPlaceholderMessage.copyWith(text: fullResponse);
        notifyListeners(); // Notify listeners for UI update
      }

      _setStatus(ChatStatus.idle);

    } catch (e) {
      _errorMessage = 'Failed to get AI response: ${e.toString()}';
      _setStatus(ChatStatus.error);
      // Replace the last (placeholder) message with an error state message
      _messages.last = aiPlaceholderMessage.copyWith(
        text: "Error: Could not connect to AI. Please try again.",
        isError: true,
      );
    } finally {
      // Ensure status is reset if not already
      if (_status == ChatStatus.streaming) {
         _setStatus(ChatStatus.idle);
      }
    }
  }

  /// Clears the entire chat history.
  void clearChat() {
    _messages.clear();
    // Re-add the initial welcome message
     _messages.add(ChatMessage(
      text: "Hey there! I'm Stremini - your AI assistant & digital bodyguard. I can help with chat, translation, security, and more.",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  // --- Internal Helpers ---
  void _addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void _setStatus(ChatStatus newStatus) {
    _status = newStatus;
    if (newStatus != ChatStatus.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }
}
