import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_drawer.dart';

class CustomKeyboardScreen extends StatefulWidget {
  const CustomKeyboardScreen({Key? key}) : super(key: key);

  @override
  State<CustomKeyboardScreen> createState() => _CustomKeyboardScreenState();
}

class _CustomKeyboardScreenState extends State<CustomKeyboardScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showKeyboard = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _showKeyboard = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertText(String text) {
    final cursorPos = _controller.selection.baseOffset;
    final currentText = _controller.text;

    String newText;
    int newCursorPos;

    if (cursorPos < 0) {
      newText = currentText + text;
      newCursorPos = newText.length;
    } else {
      newText = currentText.substring(0, cursorPos) +
          text +
          currentText.substring(cursorPos);
      newCursorPos = cursorPos + text.length;
    }

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }

  void _backspace() {
    final cursorPos = _controller.selection.baseOffset;
    final currentText = _controller.text;

    if (cursorPos > 0) {
      final newText = currentText.substring(0, cursorPos - 1) +
          currentText.substring(cursorPos);

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos - 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Keyboard')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Tap the text field to use the custom keyboard'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    readOnly: true,
                    showCursor: true,
                    decoration: const InputDecoration(
                      labelText: 'Type here',
                      hintText: 'Tap to activate keyboard...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 6,
                  ),
                ],
              ),
            ),
          ),

          // Custom Keyboard
          if (_showKeyboard) _buildKeyboard(),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    final theme = Theme.of(context);

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.all(8),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Row 1
            _buildKeyRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P']),
            const SizedBox(height: 6),
            // Row 2
            _buildKeyRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L']),
            const SizedBox(height: 6),
            // Row 3
            Row(
              children: [
                const SizedBox(width: 24),
                ..._buildKeys(['Z', 'X', 'C', 'V', 'B', 'N', 'M']),
                const SizedBox(width: 8),
                _buildActionKey(Icons.backspace, _backspace, Colors.red.withOpacity(0.3)),
              ],
            ),
            const SizedBox(height: 6),
            // Row 4 - Space and actions
            Row(
              children: [
                _buildActionKey(Icons.keyboard_hide, () {
                  _focusNode.unfocus();
                }, theme.primaryColor.withOpacity(0.3)),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _insertText(' '),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('Space')),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionKey(Icons.check, () {
                  _focusNode.unfocus();
                }, Colors.green.withOpacity(0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _buildKeys(keys),
    );
  }

  List<Widget> _buildKeys(List<String> keys) {
    return keys
        .map((k) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildKey(k),
              ),
            ))
        .toList();
  }

  Widget _buildKey(String char) {
    return GestureDetector(
      onTap: () => _insertText(char),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            char,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}
