
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stremniapp/services/api_service.dart';

// Define the states for the screen
enum ScreenState { initial, loading, success, error }

class ScreenAnalyzerScreen extends StatefulWidget {
  const ScreenAnalyzerScreen({Key? key}) : super(key: key);

  @override
  _ScreenAnalyzerScreenState createState() => _ScreenAnalyzerScreenState();
}

class _ScreenAnalyzerScreenState extends State<ScreenAnalyzerScreen> {
  // State management variables
  ScreenState _currentState = ScreenState.initial;
  String _errorMessage = '';
  dynamic _analysisResult;
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;

  // API service instance
  final ApiService _apiService = ApiService();

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _textController.clear(); // Clear text when image is selected
      });
    }
  }

  // Function to call the backend for analysis
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
        result = await _apiService.uploadImage('analyze-image', _selectedImage!);
      } else {
        result = await _apiService.post('analyze-text', {'text': _textController.text});
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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Analyzer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to analyze',
                border: OutlineInputBorder(),
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
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Image'),
            ),
            const SizedBox(height: 16),
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
            ElevatedButton(
              onPressed: (_currentState == ScreenState.loading) ? null : _analyzeContent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text('Analyze'),
            ),
            const SizedBox(height: 24),
            _buildResultWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultWidget() {
    switch (_currentState) {
      case ScreenState.loading:
        return const Center(child: CircularProgressIndicator());
      case ScreenState.success:
        return Card(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analysis Result:', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_analysisResult),
                  style: const TextStyle(fontFamily: 'monospace'),
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
                Text('An Error Occurred:', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red)),
                const SizedBox(height: 8),
                Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        );
      case ScreenState.initial:
      default:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Enter text or select an image to start analysis.',
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}
