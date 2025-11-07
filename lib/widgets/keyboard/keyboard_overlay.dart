import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/keyboard_provider.dart';

class KeyboardOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const KeyboardOverlay({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<KeyboardOverlay> createState() => _KeyboardOverlayState();
}

class _KeyboardOverlayState extends State<KeyboardOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _textController = TextEditingController();
  int _selectedFeature = 0; // 0: Complete, 1: Tone, 2: Translate

  final List<Map<String, dynamic>> _features = [
    {'icon': Icons.auto_awesome, 'label': 'Complete', 'color': Color(0xFF00D9FF)},
    {'icon': Icons.sentiment_satisfied, 'label': 'Tone', 'color': Color(0xFFFF6B6B)},
    {'icon': Icons.translate, 'label': 'Translate', 'color': Color(0xFF4ECDC4)},
  ];

  final List<String> _toneOptions = [
    'Professional',
    'Casual',
    'Friendly',
    'Formal',
    'Enthusiastic',
    'Empathetic',
  ];

  final List<String> _languageOptions = [
    'Spanish',
    'French',
    'German',
    'Hindi',
    'Marathi',
    'Chinese',
    'Japanese',
  ];

  String? _selectedTone;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(24),
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
                _buildHeader(),
                _buildFeatureSelector(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.keyboard,
              color: Color(0xFF00D9FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Keyboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Smart text assistance',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleClose,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSelector() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _features.length,
        itemBuilder: (context, index) {
          final feature = _features[index];
          final isSelected = _selectedFeature == index;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedFeature = index;
                if (index == 1) _selectedTone = null;
                if (index == 2) _selectedLanguage = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? feature['color']
                    : const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? feature['color']
                      : Colors.white.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    feature['icon'],
                    color: isSelected ? Colors.black : Colors.white70,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<KeyboardProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputSection(),
              const SizedBox(height: 16),
              if (_selectedFeature == 1) _buildToneSelector(),
              if (_selectedFeature == 2) _buildLanguageSelector(),
              const SizedBox(height: 16),
              _buildActionButton(provider),
              if (provider.result != null) ...[
                const SizedBox(height: 24),
                _buildResultSection(provider.result!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Text',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _getHintText(),
              hintStyle: const TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _textController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  String _getHintText() {
    switch (_selectedFeature) {
      case 0:
        return 'Start typing and AI will complete...';
      case 1:
        return 'Enter text to change tone...';
      case 2:
        return 'Enter text to translate...';
      default:
        return 'Enter your text...';
    }
  }

  Widget _buildToneSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Tone',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _toneOptions.map((tone) {
            final isSelected = _selectedTone == tone;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTone = tone);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6B6B)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  tone,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Language',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languageOptions.map((lang) {
            final isSelected = _selectedLanguage == lang;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedLanguage = lang);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4ECDC4)
                      : const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4ECDC4)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  lang,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(KeyboardProvider provider) {
    bool canProcess = _textController.text.isNotEmpty;
    if (_selectedFeature == 1) canProcess = canProcess && _selectedTone != null;
    if (_selectedFeature == 2)
      canProcess = canProcess && _selectedLanguage != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isLoading || !canProcess
            ? null
            : () => _processText(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: _features[_selectedFeature]['color'],
          disabledBackgroundColor: const Color(0xFF0F3460),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: provider.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                _getActionButtonText(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getActionButtonText() {
    switch (_selectedFeature) {
      case 0:
        return 'Complete Text';
      case 1:
        return 'Change Tone';
      case 2:
        return 'Translate';
      default:
        return 'Process';
    }
  }

  Future<void> _processText(KeyboardProvider provider) async {
    HapticFeedback.mediumImpact();

    switch (_selectedFeature) {
      case 0:
        await provider.completeText(_textController.text);
        break;
      case 1:
        if (_selectedTone != null) {
          await provider.changeTone(_textController.text, _selectedTone!);
        }
        break;
      case 2:
        if (_selectedLanguage != null) {
          await provider.translateText(_textController.text, _selectedLanguage!);
        }
        break;
    }
  }

  Widget _buildResultSection(String result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Result',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Color(0xFF00D9FF), size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF00D9FF),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _features[_selectedFeature]['color'].withOpacity(0.3)),
          ),
          child: Text(
            result,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
