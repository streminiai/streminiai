import 'package:flutter/material.dart';
import '../../services/stremini_api_service.dart';

class TranslationOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const TranslationOverlay({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<TranslationOverlay> createState() => _TranslationOverlayState();
}

class _TranslationOverlayState extends State<TranslationOverlay> {
  final StreminiApiService _apiService = StreminiApiService();
  final TextEditingController _textController = TextEditingController();
  
  String _sourceLanguage = 'auto';
  String _targetLanguage = 'en';
  String _translatedText = '';
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _languages = [
    {'code': 'auto', 'name': 'Auto Detect'},
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'mr', 'name': 'Marathi'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'ru', 'name': 'Russian'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _translateText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter text to translate';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _translatedText = '';
    });

    try {
      final result = await _apiService.translateScreen(
        texts: [text],
        targetLanguage: _targetLanguage,
      );

      setState(() {
        _translatedText = result['translations']?[0] ?? 'Translation failed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Translation failed: $e';
        _isLoading = false;
      });
    }
  }

  void _swapLanguages() {
    if (_sourceLanguage == 'auto') return;
    
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
      
      // Swap text too
      final tempText = _textController.text;
      _textController.text = _translatedText;
      _translatedText = tempText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 550,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Language Selector
          _buildLanguageSelector(),
          
          // Input Text Area
          _buildInputArea(),
          
          // Translate Button
          _buildTranslateButton(),
          
          // Output Text Area
          _buildOutputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00B4DB),
            Color(0xFF0083B0),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.translate,
              color: Color(0xFF0083B0),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Translator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Instant translation',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Close Button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Source Language
          Expanded(
            child: _buildLanguageDropdown(
              value: _sourceLanguage,
              onChanged: (value) {
                setState(() {
                  _sourceLanguage = value!;
                });
              },
            ),
          ),
          
          // Swap Button
          IconButton(
            icon: Icon(
              Icons.swap_horiz,
              color: Color(0xFF0083B0),
            ),
            onPressed: _swapLanguages,
          ),
          
          // Target Language
          Expanded(
            child: _buildLanguageDropdown(
              value: _targetLanguage,
              onChanged: (value) {
                setState(() {
                  _targetLanguage = value!;
                });
              },
              excludeAuto: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
    bool excludeAuto = false,
  }) {
    final languages = excludeAuto 
        ? _languages.where((lang) => lang['code'] != 'auto').toList()
        : _languages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: languages.map((lang) {
          return DropdownMenuItem(
            value: lang['code'],
            child: Text(
              lang['name']!,
              style: TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInputArea() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: TextField(
          controller: _textController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: 'Enter text to translate...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTranslateButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _translateText,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0083B0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Translate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOutputArea() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF0083B0).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF0083B0).withOpacity(0.2)),
        ),
        child: _buildOutputContent(),
      ),
    );
  }

  Widget _buildOutputContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_translatedText.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.translate,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Translation will appear here',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: SelectableText(
        _translatedText,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
