

import 'package:flutter_riverpod/legacy.dart';

class ChatWindowState {
  final String overlayMode; // "icon", "radial", or "maximized"

  ChatWindowState({this.overlayMode = "icon"});

  ChatWindowState copyWith({String? overlayMode}) {
    return ChatWindowState(
      overlayMode: overlayMode ?? this.overlayMode,
    );
  }
}

class ChatWindowStateNotifier extends StateNotifier<ChatWindowState> {
  ChatWindowStateNotifier() : super(ChatWindowState());

  void setMode(String mode) {
    state = state.copyWith(overlayMode: mode);
  }

  void cycleMode() {
    final newMode = switch (state.overlayMode) {
      "icon" => "radial",
      "radial" => "maximized",
      _ => "icon", // maximized or unknown returns to icon
    };
    state = state.copyWith(overlayMode: newMode);
  }
}

final chatWindowStateProvider =
    StateNotifierProvider<ChatWindowStateNotifier, ChatWindowState>(
  (ref) => ChatWindowStateNotifier(),
);
