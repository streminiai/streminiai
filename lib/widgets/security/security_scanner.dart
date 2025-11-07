import 'package:flutter/material.dart';
import '../../services/stremini_api_service.dart';
import '../../models/security_scan_result.dart';

class SecurityScanner extends StatefulWidget {
  final VoidCallback onClose;

  const SecurityScanner({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SecurityScanner> createState() => _SecurityScannerState();
}

class _SecurityScannerState extends State<SecurityScanner> {
  final StreminiApiService _apiService = StreminiApiService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  
  bool _isScanning = false;
  SecurityScanResult? _scanResult;
  Map<String, dynamic>? _urlCheckResult;
  int _selectedTab = 0; // 0 = Text Scan, 1 = URL Check

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _scanContent() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter content to scan');
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    try {
      final result = await _apiService.scanContent(text);
      setState(() {
        _scanResult = result;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showError('Scan failed: $e');
    }
  }

  Future<void> _checkUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('Please enter a URL to check');
      return;
    }

    setState(() {
      _isScanning = true;
      _urlCheckResult = null;
    });

    try {
      final result = await _apiService.checkUrl(url);
      setState(() {
        _urlCheckResult = result;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showError('URL check failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 580,
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
          
          // Tabs
          _buildTabs(),
          
          // Content
          Expanded(
            child: _selectedTab == 0 
                ? _buildTextScanTab()
                : _buildUrlCheckTab(),
          ),
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
            Color(0xFFFF6B6B),
            Color(0xFFEE5A6F),
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
              Icons.security,
              color: Color(0xFFFF6B6B),
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
                  'Security Scanner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Detect scams & threats',
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

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Text Scan',
              icon: Icons.text_fields,
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'URL Check',
              icon: Icons.link,
              index: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedTab == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF6B6B) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextScanTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input Area
          Expanded(
            flex: 2,
            child: Container(
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
                  hintText: 'Paste message or content to scan...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Scan Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _scanContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Scan for Threats',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Results Area
          Expanded(
            flex: 2,
            child: _buildScanResults(),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUrlCheckTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // URL Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Enter URL to check...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.link, color: Colors.grey[400]),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Check Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _checkUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Check URL Safety',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Results Area
          Expanded(
            child: _buildUrlResults(),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScanResults() {
    if (_scanResult == null) {
      return _buildEmptyState(
        icon: Icons.security,
        message: 'Scan results will appear here',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getScanResultColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getScanResultColor()),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getScanResultIcon(),
                  color: _getScanResultColor(),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scanResult!.isSafe ? 'Content is Safe' : 'Threat Detected!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getScanResultColor(),
                        ),
                      ),
                      Text(
                        'Confidence: ${(_scanResult!.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _scanResult!.analysis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (_scanResult!.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Warnings:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...(_scanResult!.warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(warning, style: TextStyle(fontSize: 13))),
                  ],
                ),
              )).toList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrlResults() {
    if (_urlCheckResult == null) {
      return _buildEmptyState(
        icon: Icons.link,
        message: 'URL check results will appear here',
      );
    }

    final isSafe = _urlCheckResult!['isSafe'] ?? true;
    final analysis = _urlCheckResult!['analysis'] ?? 'No analysis available';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isSafe ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSafe ? Colors.green : Colors.red),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSafe ? Icons.check_circle : Icons.warning,
                  color: isSafe ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isSafe ? 'URL is Safe' : 'Suspicious URL!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSafe ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              analysis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScanResultColor() {
    if (_scanResult == null) return Colors.grey;
    return _scanResult!.isSafe ? Colors.green : Colors.red;
  }

  IconData _getScanResultIcon() {
    if (_scanResult == null) return Icons.help_outline;
    return _scanResult!.isSafe ? Icons.check_circle : Icons.warning;
  }
}
