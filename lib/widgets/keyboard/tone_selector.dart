// lib/widgets/keyboard/tone_selector.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Tone selector for keyboard feature
class ToneSelector extends StatefulWidget {
  final Function(String) onToneSelected;
  final String? selectedTone;

  const ToneSelector({
    Key? key,
    required this.onToneSelected,
    this.selectedTone,
  }) : super(key: key);

  @override
  State<ToneSelector> createState() => _ToneSelectorState();
}

class _ToneSelectorState extends State<ToneSelector> {
  String? _selectedTone;

  @override
  void initState() {
    super.initState();
    _selectedTone = widget.selectedTone;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: AppConstants.spaceM,
        mainAxisSpacing: AppConstants.spaceM,
      ),
      itemCount: AppConstants.toneOptions.length,
      itemBuilder: (context, index) {
        final tone = AppConstants.toneOptions[index];
        final isSelected = tone == _selectedTone;

        return ToneChip(
          label: tone,
          icon: _getToneIcon(tone),
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedTone = tone;
            });
            AppHelpers.hapticFeedback(light: true);
            widget.onToneSelected(tone);
          },
        );
      },
    );
  }

  IconData _getToneIcon(String tone) {
    switch (tone.toLowerCase()) {
      case 'professional':
        return Icons.business;
      case 'casual':
        return Icons.emoji_emotions;
      case 'formal':
        return Icons.assignment;
      case 'friendly':
        return Icons.favorite;
      case 'brief':
        return Icons.short_text;
      case 'detailed':
        return Icons.notes;
      default:
        return Icons.text_fields;
    }
  }
}

/// Individual tone chip
class ToneChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ToneChip({
    Key? key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppConstants.keyboardColor.withOpacity(0.15)
          : AppConstants.cardDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppConstants.keyboardColor
                  : AppConstants.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spaceM,
            vertical: AppConstants.spaceS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppConstants.keyboardColor
                    : AppConstants.textSecondary,
                size: 20,
              ),
              SizedBox(width: AppConstants.spaceS),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppConstants.bodySize,
                    color: isSelected
                        ? AppConstants.textPrimary
                        : AppConstants.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal tone selector (scrollable)
class HorizontalToneSelector extends StatefulWidget {
  final Function(String) onToneSelected;
  final String? selectedTone;

  const HorizontalToneSelector({
    Key? key,
    required this.onToneSelected,
    this.selectedTone,
  }) : super(key: key);

  @override
  State<HorizontalToneSelector> createState() => _HorizontalToneSelectorState();
}

class _HorizontalToneSelectorState extends State<HorizontalToneSelector> {
  String? _selectedTone;

  @override
  void initState() {
    super.initState();
    _selectedTone = widget.selectedTone;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
        itemCount: AppConstants.toneOptions.length,
        itemBuilder: (context, index) {
          final tone = AppConstants.toneOptions[index];
          final isSelected = tone == _selectedTone;

          return Padding(
            padding: EdgeInsets.only(right: AppConstants.spaceS),
            child: _HorizontalToneChip(
              label: tone,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedTone = tone;
                });
                AppHelpers.hapticFeedback(light: true);
                widget.onToneSelected(tone);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HorizontalToneChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _HorizontalToneChip({
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppConstants.keyboardColor
          : AppConstants.cardDark,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: isSelected
                  ? AppConstants.keyboardColor
                  : AppConstants.dividerColor,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppConstants.bodySize,
              color: isSelected
                  ? Colors.black
                  : AppConstants.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tone preview card
class TonePreviewCard extends StatelessWidget {
  final String tone;
  final String example;

  const TonePreviewCard({
    Key? key,
    required this.tone,
    required this.example,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceS,
      ),
      padding: EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.keyboardColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tone,
                  style: TextStyle(
                    fontSize: AppConstants.captionSize,
                    color: AppConstants.keyboardColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spaceS),
          Text(
            example,
            style: TextStyle(
              fontSize: AppConstants.bodySize,
              color: AppConstants.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
