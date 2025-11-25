import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stremniapp/services/api_service.dart';
import 'package:stremniapp/routing/app_drawer.dart';

class ScreenAnalyzerScreen extends StatefulWidget {
  const ScreenAnalyzerScreen({Key? key}) : super(key: key);

  @override
  State<ScreenAnalyzerScreen> createState() => _ScreenAnalyzerScreenState();
}

class _ScreenAnalyzerScreenState extends State<ScreenAnalyzerScreen> {
  final TextEditingController _textController = TextEditingController();
  final ApiService _api = ApiService();

  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _textController.clear();
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _textController.clear();
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _analyze() async {
    if (_textController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text or select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      Map<String, dynamic> result;

      if (_selectedImage != null) {
        result = await _api.uploadImage('image/analyze-image', _selectedImage!);
      } else {
        result = await _api.analyzeText(_textController.text);
      }

      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clear() {
    setState(() {
      _textController.clear();
      _selectedImage = null;
      _result = null;
      _error = null;
    });
  }

  Color _getSafetyColor() {
    if (_result == null) return Colors.grey;
    final safety = (_result!['safety'] ?? '').toString().toLowerCase();
    if (safety.contains('safe') && !safety.contains('unsafe')) return Colors.green;
    if (safety.contains('scam') || safety.contains('phishing')) return Colors.red;
    return Colors.orange;
  }

  IconData _getSafetyIcon() {
    if (_result == null) return Icons.help_outline;
    final safety = (_result!['safety'] ?? '').toString().toLowerCase();
    if (safety.contains('safe') && !safety.contains('unsafe')) return Icons.check_circle;
    if (safety.contains('scam') || safety.contains('phishing')) return Icons.dangerous;
    return Icons.warning;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clear,
            tooltip: 'Clear',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: theme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Analyze text or images for scams, phishing, and suspicious content',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Text input
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to analyze',
                hintText: 'Paste suspicious messages, links, or content...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (text) {
                if (text.isNotEmpty && _selectedImage != null) {
                  setState(() => _selectedImage = null);
                }
              },
            ),
            const SizedBox(height: 16),

            // Image buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected image preview
            if (_selectedImage != null)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primaryColor),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Analyze button
            ElevatedButton(
              onPressed: _isLoading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Analyze Content', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),

            // Results
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing content...'),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Card(
                color: Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_result != null)
              Card(
                color: _getSafetyColor().withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_getSafetyIcon(), color: _getSafetyColor(), size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _result!['safety']?.toString() ?? 'Analysis Complete',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getSafetyColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_result!['reason'] != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Reason',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_result!['reason'].toString()),
                      ],
                      if (_result!['details'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Details',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_result!['details'].toString()),
                      ],
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: const Text('View Full Response'),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              const JsonEncoder.withIndent('  ').convert(_result),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.security, size: 48, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text(
                        'Enter text or select an image to analyze',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
