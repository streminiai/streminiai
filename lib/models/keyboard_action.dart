enum KeyboardActionType {
  complete,
  tone,
  translate,
}

class KeyboardAction {
  final KeyboardActionType type;
  final String inputText;
  final String? parameter; // tone type or target language

  KeyboardAction({
    required this.type,
    required this.inputText,
    this.parameter,
  });
}
