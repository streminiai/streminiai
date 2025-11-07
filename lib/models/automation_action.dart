class AutomationAction {
  final String action;
  final Map<String, dynamic>? parameters;

  AutomationAction({
    required this.action,
    this.parameters,
  });

  factory AutomationAction.fromJson(Map<String, dynamic> json) {
    return AutomationAction(
      action: json['action'] as String,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }

  bool get isOpenApp => action == 'open_app';
  bool get isSendMessage => action == 'send_message';
  bool get isTranslateScreen => action == 'translate_screen';
  bool get isUnknown => action == 'unknown';
}
