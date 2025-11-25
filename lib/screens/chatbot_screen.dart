import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stremniapp/services/api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _api = ApiService();

  final List<_Message> _messages = [];
  bool _isLoading = false;
  bool? _isConnected;

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
    final ok = await _api.testConnection();
    setState(() => _isConnected = ok);
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

    try {
      final resp = await _api.sendChatMessage(text);
      final reply = resp['response'] ??
          resp['text'] ??
          resp['message'] ??
          'No response';
      setState(() => _messages.add(_Message(text: reply, isUser: false)));
    } catch (e) {
      setState(() => _messages.add(_Message(
            text: 'Error: ${e.toString().replaceFirst("Exception: ", "")}',
            isUser: false,
          )));
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => _buildBubble(_messages[i]),
            ),
          ),

          // Loading
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
                    'Thinking...',
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
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      size: 26,
                      color: _isLoading ? theme.disabledColor : theme.primaryColor,
                    ),
                    onPressed: _isLoading ? null : _send,
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
