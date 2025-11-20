import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stremniapp/services/api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool? _connectionStatus;
  String _connectionMessage = '';

  @override
  void initState() {
    super.initState();
    _addMessage(
      "Hello! I'm Stremini AI. How can I help you today?",
      isUser: false,
    );
    // Test connection on start
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _connectionStatus = null;
      _connectionMessage = 'Testing connection...';
    });

    try {
      final isConnected = await _apiService.testConnection();
      setState(() {
        _connectionStatus = isConnected;
        _connectionMessage = isConnected 
            ? '✅ Connected to server' 
            : '❌ Cannot reach server';
      });
      
      if (!isConnected) {
        _addMessage(
          "⚠️ Warning: Cannot connect to backend server. Please check your internet connection.",
          isUser: false,
        );
      }
    } catch (e) {
      setState(() {
        _connectionStatus = false;
        _connectionMessage = '❌ Connection failed: $e';
      });
    }
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Clear input immediately
    _messageController.clear();
    
    // Add user message
    _addMessage(message, isUser: true);

    // Show loading
    setState(() => _isLoading = true);

    try {
      print('\n🚀 Sending: $message');
      
      // Send the message
      final response = await _apiService.sendChatMessage(message);
      
      print('✅ Got response: $response');
      
      // Get the AI's reply - try all possible field names
      String botReply = 'Sorry, I couldn\'t understand that.';
      
      if (response is Map<String, dynamic>) {
        // Try different possible response field names
        botReply = response['response'] ?? 
                   response['text'] ?? 
                   response['message'] ?? 
                   response['content'] ?? 
                   response['reply'] ?? 
                   response['answer'] ??
                   response['data'] ??
                   response.values.firstWhere(
                     (v) => v is String && v.isNotEmpty, 
                     orElse: () => 'No response from server'
                   );
      } else if (response is String) {
        botReply = response;
      }
      
      print('💬 Bot says: $botReply');
      
      // Add bot's response
      _addMessage(botReply, isUser: false);
      
    } catch (e) {
      print('❌ ERROR: $e');
      
      String errorMsg = e.toString().replaceFirst("Exception: ", "");
      
      // Show error in chat
      _addMessage(
        '⚠️ Error: $errorMsg',
        isUser: false,
      );
      
      // If it's a connection error, suggest testing connection
      if (errorMsg.contains('internet') || 
          errorMsg.contains('connection') ||
          errorMsg.contains('reach')) {
        _addMessage(
          'Tap the "Test Connection" button below to diagnose the issue.',
          isUser: false,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _addMessage(
        "Hello! I'm Stremini AI. How can I help you today?",
        isUser: false,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stremini AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  if (_connectionStatus != null)
                    Text(
                      _connectionMessage,
                      style: TextStyle(
                        fontSize: 11,
                        color: _connectionStatus! ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testConnection,
            tooltip: 'Test connection',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          if (_connectionStatus == false)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.2),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Not connected to server. Check internet connection.',
                      style: TextStyle(color: Colors.red[300], fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _testConnection,
                    child: const Text('Test', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask anything...',
                          hintStyle: TextStyle(color: theme.disabledColor),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isLoading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      size: 28,
                      color: _isLoading ? theme.disabledColor : theme.primaryColor,
                    ),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? theme.primaryColor.withOpacity(0.2)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message.text,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.disabledColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
