import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const String _baseUrl =
      "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev";
  
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_Message> _messages = [];
  bool _isLoading = false;
  bool? _isConnected;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
      text: "Hello! I'm Stremini AI. How can I help you today?",
      isUser: false,
    ));
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      print('🔍 Testing connection to $_baseUrl');
      final resp = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));
      
      final connected = resp.statusCode == 200 || 
                       resp.statusCode == 404 || 
                       resp.statusCode == 405;
      
      setState(() => _isConnected = connected);
      print(connected ? '✅ Connected' : '❌ Not connected (${resp.statusCode})');
    } catch (e) {
      print('❌ Connection test failed: $e');
      setState(() => _isConnected = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    Exception? lastError;
    const maxRetries = 2;
    const timeout = Duration(seconds: 15);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('📤 Sending message (attempt $attempt/$maxRetries): ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
        
        final resp = await http.post(
          Uri.parse('$_baseUrl/chat/message'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'message': text}),
        ).timeout(timeout);

        print('📥 Response status: ${resp.statusCode}');

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          try {
            final data = jsonDecode(resp.body);
            final reply = data['response'] ?? 
                         data['text'] ?? 
                         data['message'] ?? 
                         'No response from AI';
            
            print('✅ Success: ${reply.substring(0, reply.length > 100 ? 100 : reply.length)}...');
            
            setState(() {
              _messages.add(_Message(text: reply, isUser: false));
              _isLoading = false;
              _retryCount = 0;
            });
            _scrollToBottom();
            return;
          } catch (e) {
            print('⚠️ JSON parse error, using raw body');
            setState(() {
              _messages.add(_Message(text: resp.body, isUser: false));
              _isLoading = false;
            });
            _scrollToBottom();
            return;
          }
        } else if (resp.statusCode >= 500) {
          lastError = Exception('Server is busy. Please try again.');
          if (attempt < maxRetries) {
            print('⏳ Server error, retrying...');
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
        } else if (resp.statusCode == 429) {
          lastError = Exception('Too many requests. Please wait a moment.');
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        } else {
          String msg = 'Error ${resp.statusCode}';
          try {
            final err = jsonDecode(resp.body);
            msg = err['error']?.toString() ?? err['message']?.toString() ?? msg;
          } catch (_) {}
          throw Exception(msg);
        }
      } on SocketException catch (e) {
        print('❌ Socket error: $e');
        lastError = Exception('No internet connection. Please check and try again.');
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
      } on TimeoutException catch (e) {
        print('⏱️ Timeout: $e');
        lastError = Exception('Request timed out. Please try again.');
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
      } catch (e) {
        print('❌ Unknown error: $e');
        lastError = Exception(e.toString().replaceFirst('Exception: ', ''));
        break;
      }
    }

    // All attempts failed
    print('❌ All attempts failed');
    setState(() {
      _messages.add(_Message(
        text: lastError?.toString().replaceFirst('Exception: ', '') ?? 
              'Something went wrong. Please try again.',
        isUser: false,
      ));
      _isLoading = false;
      _retryCount++;
    });
    _scrollToBottom();

    // Suggest checking connection after multiple failures
    if (_retryCount >= 3) {
      setState(() => _isConnected = false);
      _showConnectionDialog();
    }
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Connection Issue'),
          ],
        ),
        content: const Text(
          'Having trouble connecting to the server. Please check:\n\n'
          '• Your internet connection\n'
          '• If the server is online\n'
          '• Try again in a few moments',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _testConnection();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Test Connection'),
          ),
        ],
      ),
    );
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

  void _clear() {
    setState(() {
      _messages.clear();
      _messages.add(_Message(
        text: "Hello! I'm Stremini AI. How can I help you today?",
        isUser: false,
      ));
      _retryCount = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stremini AI', style: TextStyle(fontSize: 17)),
                if (_isConnected != null)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected! ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected! ? 'Connected' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isConnected! ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected == true ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected == true ? Colors.green : Colors.red,
            ),
            onPressed: _testConnection,
            tooltip: 'Test connection',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clear,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection warning
          if (_isConnected == false)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.2),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Not connected to server',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _testConnection,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildBubble(_messages[i]),
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),

          // Input
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
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Ask anything...',
                          hintStyle: TextStyle(color: theme.disabledColor),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        enabled: !_isLoading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [Colors.grey, Colors.grey.shade700]
                            : [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        size: 22,
                        color: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Message msg) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: msg.isUser
                      ? theme.primaryColor.withOpacity(0.2)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: msg.isUser
                      ? Border.all(color: theme.primaryColor.withOpacity(0.3))
                      : null,
                ),
                child: SelectableText(
                  msg.text,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 10),
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
}

class _Message {
  final String text;
  final bool isUser;

  _Message({required this.text, required this.isUser});
}
