import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/stremini_api_service.dart';

class AIKeyboardWidget extends StatefulWidget {
  final VoidCallback onClose;

  const AIKeyboardWidget({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AIKeyboardWidget> createState() => _AIKeyboardWidgetState();
}

class _AIKeyboardWidgetState extends State<AIKeyboardWidget> {
  final TextEditingController _textController = TextEditingController();
  String _selectedAction = 'complete';
  String _selectedTone = 'professional';
  String _targetLanguage = 'es';
  bool _isLoading = false;
  String _result = '';

  final List<Map<String, dynamic>> _actions = [
    {'id': 'complete', 'label': 'Complete', 'icon': Icons.auto_fix_high},
    {'id': 'tone', 'label': 'Change Tone', 'icon': Icons.mood},
    {'id': 'translate', 'label': 'Translate', 'icon': Icons.translate},
  ];

  final List<String> _tones = [
    'professional',
    'casual',
    'friendly',
    'formal',
    'humorous'
  ];

  final Map<String, String> _languages = {
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'hi': 'Hindi',
    'zh': 'Chinese',
    'ja': 'Japanese',
  };

  Future<void> _processText() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final apiService = context.read<StreminiApiService>();

      switch (_selectedAction) {
        case 'complete':
          final response =
              await apiService.completeText(_textController.text);
          setState(() => _result = response['completion'] ?? '');
          break;

        case 'tone':
          final response = await apiService.changeTone(
            _textController.text,
            _selectedTone,
          );
          setState(() => _result = response['modified_text'] ?? '');
          break;

        case 'translate':
          final response = await apiService.translateKeyboardText(
            _textController.text,
            _targetLanguage,
          );
          setState(() => _result = response['translated_text'] ?? '');
          break;
      }
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.keyboard, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'AI Keyboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Action Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _actions.map((action) {
                final isSelected = _selectedAction == action['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAction = action['id']),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0A84FF)
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(action['icon'], color: Colors.white, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            action['label'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Options
          if (_selectedAction == 'tone')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedTone,
                dropdownColor: const Color(0xFF2C2C2E),
                decoration: InputDecoration(
                  labelText: 'Select Tone',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _tones.map((tone) {
                  return DropdownMenuItem(
                    value: tone,
                    child: Text(
                      tone[0].toUpperCase() + tone.substring(1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedTone = value!),
              ),
            ),

          if (_selectedAction == 'translate')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _targetLanguage,
                dropdownColor: const Color(0xFF2C2C2E),
                decoration: InputDecoration(
                  labelText: 'Target Language',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _languages.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _targetLanguage = value!),
              ),
            ),

          const SizedBox(height: 16),

          // Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _textController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your text here...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Process Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processText,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Process',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          // Result
          if (_result.isNotEmpty)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Result',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                            onPressed: () {
                              // Copy to clipboard functionality
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
