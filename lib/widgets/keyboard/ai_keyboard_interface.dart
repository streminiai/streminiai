// lib/widgets/keyboard/ai_keyboard_interface.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stremini_chatbot/features/keyboard_provider.dart';
import 'package:stremini_chatbot/widgets/common/loading_indicator.dart';

class AIKeyboardInterface extends StatefulWidget {
  // This widget should ideally receive the text from the currently focused input field.
  // For demonstration, we'll use a placeholder text field.
  final String initialText;
  final Function(String newText) onApplyText;
  
  const AIKeyboardInterface({
    super.key, 
    this.initialText = 'This is the text currently selected in your app\'s input field.',
    required this.onApplyText,
  });

  @override
  State<AIKeyboardInterface> createState() => _AIKeyboardInterfaceState();
}

class _AIKeyboardInterfaceState extends State<AIKeyboardInterface> {
  late TextEditingController _textController;
  String _selectedTone = 'Professional';
  
  final List<String> _tones = ['Professional', 'Casual', 'Friendly', 'Sarcastic', 'Technical'];
  final List<String> _languages = ['Spanish', 'French', 'German', 'Chinese'];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleAction(KeyboardProvider provider, KeyboardActionType type) {
    final currentText = _textController.text;
    if (currentText.isEmpty || provider.isProcessing) return;

    provider.clearResult(); // Clear previous results

    switch (type) {
      case KeyboardActionType.complete:
        provider.completeText(currentText);
        break;
      case KeyboardActionType.tone:
        provider.changeTone(currentText, _selectedTone);
        break;
      case KeyboardActionType.translate:
        // Assume translation is to Spanish for simplicity, or add a language picker
        provider.translateText(currentText, 'Spanish'); 
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KeyboardProvider>();
    final isProcessing = provider.isProcessing;

    // Use a compact UI, similar to a keyboard extension bar
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionChips(provider, isProcessing),
          const Divider(color: Colors.white24, height: 20),
          _buildTextInput(provider, isProcessing),
          if (isProcessing)
            const Center(child: Padding(padding: EdgeInsets.only(top: 8), child: Text('AI is thinking...', style: TextStyle(color: Colors.white70))))
          else if (provider.errorMessage != null)
            _buildErrorState(provider.errorMessage!),
          if (provider.modifiedText.isNotEmpty)
            _buildResultDisplay(provider),
        ],
      ),
    );
  }

  Widget _buildActionChips(KeyboardProvider provider, bool isProcessing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          label: 'Complete',
          icon: Icons.auto_fix_high,
          onTap: () => _handleAction(provider, KeyboardActionType.complete),
          isProcessing: isProcessing,
          color: Colors.green,
        ),
        _buildActionButton(
          label: 'Translate',
          icon: Icons.translate,
          onTap: () => _handleAction(provider, KeyboardActionType.translate),
          isProcessing: isProcessing,
          color: Colors.blue,
        ),
        _buildTonePicker(provider, isProcessing),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isProcessing,
    required Color color,
  }) {
    return ActionChip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(label),
      backgroundColor: color.withOpacity(0.7),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      onPressed: isProcessing ? null : onTap,
    );
  }

  Widget _buildTonePicker(KeyboardProvider provider, bool isProcessing) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedTone,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        dropdownColor: Colors.grey.shade800,
        style: const TextStyle(color: Colors.white),
        items: _tones.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: isProcessing
            ? null
            : (String? newValue) {
                setState(() {
                  _selectedTone = newValue!;
                });
                _handleAction(provider, KeyboardActionType.tone);
              },
      ),
    );
  }

  Widget _buildTextInput(KeyboardProvider provider, bool isProcessing) {
    // Show the currently selected text
    return TextField(
      controller: _textController,
      maxLines: 2,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Enter text to modify...',
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      readOnly: isProcessing,
    );
  }
  
  Widget _buildResultDisplay(KeyboardProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              provider.modifiedText,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          // Button to apply the modified text back to the app's input field
          InkWell(
            onTap: () {
              widget.onApplyText(provider.modifiedText);
              provider.clearResult(); // Clear result after applying
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        'Error: ${error.split(':').last}',
        style: TextStyle(color: Colors.red.shade400, fontSize: 12),
      ),
    );
  }
}
