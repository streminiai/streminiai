import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stremniapp/services/api_service.dart';

enum ScreenState { initial, loading, success, error }

class ScreenAnalyzerScreen extends StatefulWidget {
  const ScreenAnalyzerScreen({Key? key}) : super(key: key);

  @override
  _ScreenAnalyzerScreenState createState() => _ScreenAnalyzerScreenState();
}

class _ScreenAnalyzerScreenState extends State<ScreenAnalyzerScreen> {
  ScreenState _currentState = ScreenState.initial;
  String _errorMessage = '';
  dynamic _analysisResult;
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;

  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _textController.clear();
      });
    }
  }

  Future<void> _analyzeContent() async {
    if (_textController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text or select an image.')),
      );
      return;
    }

    setState(() {
      _currentState = ScreenState.loading;
    });

    try {
      dynamic result;
      if (_selectedImage != null) {
        // Analyze image
        result = await _apiService.uploadImage('image/analyze-image', _selectedImage!);
      } else {
        // Analyze text
        result = await _apiService.analyzeText(_textController.text);
      }

      setState(() {
        _currentState = ScreenState.success;
        _analysisResult = result;
      });
    } catch (e) {
      setState(() {
        _currentState = ScreenState.error;
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  Color _getSafetyColor() {
    if (_analysisResult == null) return Colors.grey;
    
    final safety = _analysisResult['safety']?.toString().toLowerCase() ?? '';
    if (safety.contains('safe') && !safety.contains('unsafe')) {
      return Colors.green;
    } else if (safety.contains('scam') || safety.contains('dangerous')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  IconData _getSafetyIcon() {
    if (_analysisResult == null) return Icons.help_outline;
    
    final safety = _analysisResult['safety']?.toString().toLowerCase() ?? '';
    if (safety.contains('safe') && !safety.contains('unsafe')) {
      return Icons.check_circle;
    } else if (safety.contains('scam') || safety.contains('dangerous')) {
      return Icons.dangerous;
    }
    return Icons.warning;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Analyzer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Analyze text or images for scams, phishing, and suspicious content',
                        style: TextStyle(fontSize: 14),
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
                border: OutlineInputBorder(),
                hintText: 'Paste suspicious messages, links, or content...',
              ),
              maxLines: 5,
              onChanged: (text) {
                if (text.isNotEmpty && _selectedImage != null) {
                  setState(() {
                    _selectedImage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Image picker button
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Image to Analyze'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            
            // Selected image preview
            if (_selectedImage != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 24),
            
            // Analyze button
            ElevatedButton(
              onPressed: (_currentState == ScreenState.loading) ? null : _analyzeContent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: _currentState == ScreenState.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Analyze Content', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            
            // Results
            _buildResultWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultWidget() {
    switch (_currentState) {
      case ScreenState.loading:
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing content...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
        
      case ScreenState.success:
        return Card(
          color: _getSafetyColor().withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getSafetyIcon(),
                      color: _getSafetyColor(),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _analysisResult['safety']?.toString() ?? 'Analysis Complete',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getSafetyColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_analysisResult['reason'] != null) ...[
                  Text(
                    'Reason:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_analysisResult['reason'].toString()),
                  const SizedBox(height: 12),
                ],
                
                if (_analysisResult['details'] != null) ...[
                  Text(
                    'Details:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_analysisResult['details'].toString()),
                  const SizedBox(height: 12),
                ],
                
                if (_analysisResult['text'] != null && _analysisResult['text'].toString().isNotEmpty) ...[
                  Text(
                    'Extracted Text:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(_analysisResult['text'].toString()),
                  const SizedBox(height: 12),
                ],
                
                if (_analysisResult['threatLevel'] != null) ...[
                  Text(
                    'Threat Level: ${_analysisResult['threatLevel']}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getSafetyColor(),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Full JSON (collapsible)
                ExpansionTile(
                  title: const Text('View Full Response'),
                  children: [
                    SelectableText(
                      const JsonEncoder.withIndent('  ').convert(_analysisResult),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        
      case ScreenState.error:
        return Card(
          color: Colors.red.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Error Occurred',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _currentState = ScreenState.initial),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
        
      case ScreenState.initial:
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: const [
                Icon(Icons.security, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Enter text or select an image to start security analysis',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
    }
  }
}
