// lib/widgets/floating_widget/feature_selection_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Define the possible features that can be opened
enum StreminiFeature {
  chat,
  translate,
  security,
  keyboard,
  settings,
  automation,
}

// Simple Provider to manage the current active feature, used by OverlayMain
class FeatureController with ChangeNotifier {
  StreminiFeature? _activeFeature;

  StreminiFeature? get activeFeature => _activeFeature;

  void setActiveFeature(StreminiFeature feature) {
    if (_activeFeature == feature) {
      _activeFeature = null; // Toggle off if already active
    } else {
      _activeFeature = feature; // Set new active feature
    }
    notifyListeners();
  }

  void closeOverlay() {
    _activeFeature = null;
    notifyListeners();
  }
}

class FeatureSelectionMenu extends StatelessWidget {
  const FeatureSelectionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // The FeatureController should be provided higher up in the widget tree (e.g., in OverlayMain)
    final featureController = context.watch<FeatureController>();
    
    // Using a Circular menu style as suggested by the floating UI image
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          alignment: WrapAlignment.center,
          children: [
            _buildFeatureButton(
              context,
              featureController,
              feature: StreminiFeature.chat,
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              color: Colors.green,
            ),
            _buildFeatureButton(
              context,
              featureController,
              feature: StreminiFeature.translate,
              icon: Icons.g_translate_outlined,
              label: 'Translate',
              color: Colors.blue,
            ),
            _buildFeatureButton(
              context,
              featureController,
              feature: StreminiFeature.security,
              icon: Icons.security_outlined,
              label: 'Security',
              color: Colors.red,
            ),
            _buildFeatureButton(
              context,
              featureController,
              feature: StreminiFeature.keyboard,
              icon: Icons.keyboard_outlined,
              label: 'Keyboard',
              color: Colors.purple,
            ),
            _buildFeatureButton(
              context,
              featureController,
              feature: StreminiFeature.automation,
              icon: Icons.mic_none,
              label: 'Voice',
              color: Colors.orange,
            ),
            _buildFeatureButton(
              context,
              featureController,
              feature: StreminiFeature.settings,
              icon: Icons.settings_outlined,
              label: 'Settings',
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
      BuildContext context,
      FeatureController controller,
      {required StreminiFeature feature,
      required IconData icon,
      required String label,
      required Color color}) {
    final isActive = controller.activeFeature == feature;
    final size = 60.0;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            controller.setActiveFeature(feature);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.9) : color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: isActive ? Border.all(color: color, width: 2.5) : null,
              boxShadow: isActive
                  ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)]
                  : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 10,
          ),
        )
      ],
    );
  }
}
