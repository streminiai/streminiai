// lib/widgets/common/custom_text_field.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Custom text field matching app theme
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const CustomTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.textInputAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      enabled: enabled,
      readOnly: readOnly,
      focusNode: focusNode,
      textInputAction: textInputAction,
      style: TextStyle(
        color: AppConstants.textPrimary,
        fontSize: AppConstants.bodySize,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppConstants.textSecondary)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppConstants.inputFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.securityColor,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.securityColor,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines! > 1 ? 16 : 14,
        ),
        hintStyle: TextStyle(
          color: AppConstants.textSecondary,
          fontSize: AppConstants.bodySize,
        ),
        labelStyle: TextStyle(
          color: AppConstants.textSecondary,
          fontSize: AppConstants.bodySize,
        ),
        counterStyle: TextStyle(
          color: AppConstants.textSecondary,
          fontSize: AppConstants.captionSize,
        ),
      ),
    );
  }
}

/// Chat input field with send button
class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onSend;
  final VoidCallback? onVoice;
  final bool isLoading;
  final String? hintText;

  const ChatInputField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.onSend,
    this.onVoice,
    this.isLoading = false,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceS,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppConstants.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Voice button
          if (onVoice != null)
            IconButton(
              onPressed: onVoice,
              icon: Icon(Icons.mic_outlined),
              color: AppConstants.textSecondary,
            ),
          
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.inputFieldColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: AppConstants.bodySize,
                ),
                decoration: InputDecoration(
                  hintText: hintText ?? 'Message Stremini AI...',
                  hintStyle: TextStyle(
                    color: AppConstants.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(width: AppConstants.spaceS),
          
          // Send button
          Container(
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isLoading ? null : onSend,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.textPrimary,
                        ),
                      ),
                    )
                  : Icon(Icons.send_rounded),
              color: AppConstants.textPrimary,
              iconSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search field with clear button
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final Function(String)? onChanged;
  final VoidCallback? onClear;

  const SearchField({
    Key? key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        color: AppConstants.textPrimary,
        fontSize: AppConstants.bodySize,
      ),
      decoration: InputDecoration(
        hintText: hintText ?? 'Search...',
        prefixIcon: Icon(
          Icons.search,
          color: AppConstants.textSecondary,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
                icon: Icon(
                  Icons.clear,
                  color: AppConstants.textSecondary,
                ),
              )
            : null,
        filled: true,
        fillColor: AppConstants.inputFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        hintStyle: TextStyle(
          color: AppConstants.textSecondary,
        ),
      ),
    );
  }
}
