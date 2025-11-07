import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  List<String> _suggestions = [];

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get suggestions => _suggestions;

  ChatProvider() {
    _loadChatHistory();
    _loadSuggestions();
  }

  // Load chat history from storage
  Future<void> _loadChatHistory() async {
    try {
      final history = _storage.getChatHistory();
      _messages = history.map((map) {
        return ChatMessage(
          id: map['id'] ?? '',
          content: map['content'] ?? '',
          isUser: map['role'] == 'user',
          timestamp: DateTime.now(),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  // Load suggestions
  Future<void> _loadSuggestions() async {
    try {
      _suggestions = await _apiService.getChatSuggestions();
      notifyListeners();
    } catch (e) {
      print('Error loading suggestions: $e');
    }
  }

  // Send a message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _error = null;
    notifyListeners();

    // Show loading
    _isLoading = true;
    notifyListeners();

    try {
      // Convert messages to API format
      final history = _messages
          .map((msg) => msg.toApiFormat())
          .toList();

      // Get AI response
      final response = await _apiService.sendChatMessage(content, history);

      // Add AI message
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);

      // Save to storage
      await _saveChatHistory();

    } catch (e) {
      _error = e.toString();
      print('Error sending message: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save chat history
  Future<void> _saveChatHistory() async {
    try {
      final history = _messages
          .map((msg) => msg.toApiFormat())
          .toList();
      await _storage.saveChatHistory(history);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  // Clear chat
  Future<void> clearChat() async {
    _messages.clear();
    await _storage.clearChatHistory();
    notifyListeners();
  }

  // Send suggestion
  Future<void> sendSuggestion(String suggestion) async {
    await sendMessage(suggestion);
  }

  // Retry last message
  Future<void> retryLastMessage() async {
    if (_messages.isEmpty) return;
    
    // Find last user message
    final lastUserMessage = _messages.lastWhere(
      (msg) => msg.isUser,
      orElse: () => _messages.last,
    );
    
    // Remove messages after last user message
    final index = _messages.indexOf(lastUserMessage);
    _messages = _messages.sublist(0, index + 1);
    
    // Resend
    await sendMessage(lastUserMessage.content);
  }
}
