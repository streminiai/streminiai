// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stremini_chatbot/features/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    
    // Controller for the API Key input
    final TextEditingController apiKeyController = 
        TextEditingController(text: settingsProvider.geminiApiKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stremini AI Settings'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      backgroundColor: Colors.grey.shade900,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('AI Configuration'),
            _buildApiKeyInput(context, settingsProvider, apiKeyController),
            const SizedBox(height: 20),
            
            _buildSectionHeader('Floating Widget & Overlay'),
            _buildFeatureToggle(
              label: 'Enable Floating Widget',
              value: settingsProvider.isFloatingWidgetEnabled,
              onChanged: (value) => settingsProvider.toggleFloatingWidget(value),
              subtitle: 'Toggle the Stremini AI bubble on your screen.',
            ),
            _buildFeatureToggle(
              label: 'Accessibility Service Status',
              value: settingsProvider.isAccessibilityEnabled,
              onChanged: (value) {
                 // In a real app, this would prompt the user to enable the service 
                 // and the actual status would be read from the native platform.
                 settingsProvider.setAccessibilityEnabled(value);
              },
              subtitle: 'Required for Screen Translation and Security Scanning.',
              disabled: true, // Typically read-only or requires native action
            ),
            const SizedBox(height: 20),
            
            _buildSectionHeader('Help & Info'),
            _buildInfoTile(
              icon: Icons.info_outline,
              title: 'About Stremini AI',
              onTap: () {
                // Navigate to an About screen
              },
            ),
            _buildInfoTile(
              icon: Icons.policy_outlined,
              title: 'Privacy Policy',
              onTap: () {
                // Open Privacy Policy link
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blue.shade400,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildApiKeyInput(BuildContext context, SettingsProvider provider, TextEditingController controller) {
    return Card(
      color: Colors.grey.shade800,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cloudflare Worker/Gemini API Key',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your secure API key...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.setGeminiApiKey(controller.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('API Key saved!')),
                  );
                },
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save Key'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
    bool disabled = false,
  }) {
    return SwitchListTile(
      title: Text(
        label,
        style: TextStyle(color: disabled ? Colors.white54 : Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.white70, fontSize: 12)) : null,
      value: value,
      onChanged: disabled ? null : onChanged,
      activeColor: Colors.green,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      onTap: onTap,
    );
  }
}
