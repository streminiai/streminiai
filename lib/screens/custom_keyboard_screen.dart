import 'package:flutter/material.dart';
import 'package:stremniapp/routing/app_drawer.dart';

class CustomKeyboardScreen extends StatefulWidget {
  const CustomKeyboardScreen({Key? key}) : super(key: key);

  @override
  State<CustomKeyboardScreen> createState() => _CustomKeyboardScreenState();
}

class _CustomKeyboardScreenState extends State<CustomKeyboardScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isKeyboardVisible = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Injects text into the TextField programmatically
  void _handlePaste() {
    const textToPaste = 'This text is pasted programmatically!';
    final currentText = _controller.text;
    final selection = _controller.selection;
    final newText = currentText.replaceRange(selection.start, selection.end, textToPaste);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + textToPaste.length),
    );
  }

  void _onFocusChange(bool hasFocus) {
    setState(() {
      _isKeyboardVisible = hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Keyboard UI'),
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Focus(
                onFocusChange: _onFocusChange,
                child: TextField(
                  controller: _controller,
                  readOnly: true, // Prevents system keyboard from appearing
                  showCursor: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Tap to use custom keyboard',
                  ),
                  maxLines: 10,
                ),
              ),
            ),
          ),
          // Conditionally display the custom keyboard
          if (_isKeyboardVisible)
            _CustomKeyboard(onPaste: _handlePaste),
        ],
      ),
    );
  }
}

// The UI for the custom keyboard widget
class _CustomKeyboard extends StatelessWidget {
  final VoidCallback onPaste;

  const _CustomKeyboard({Key? key, required this.onPaste}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // A simple button that acts as our custom paste button
          ElevatedButton.icon(
            icon: const Icon(Icons.content_paste),
            label: const Text('Direct Paste'),
            onPressed: onPaste,
          ),
          // Add other custom keys here if needed
        ],
      ),
    );
  }
}
