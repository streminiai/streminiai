import 'package:flutter_riverpod/flutter_riverpod.dart';

class DrawerNotifier extends StateNotifier<bool> {
  DrawerNotifier() : super(false);

  void toggleDrawer() {
    state = !state;
  }

  void closeDrawer() {
    state = false;
  }

  void openDrawer() {
    state = true;
  }
}

final drawerProvider = StateNotifierProvider<DrawerNotifier, bool>((ref) {
  return DrawerNotifier();
});

final attachmentOptionsProvider = StateNotifierProvider<AttachmentOptionsNotifier, bool>((ref) {
  return AttachmentOptionsNotifier();
});

class AttachmentOptionsNotifier extends StateNotifier<bool> {
  AttachmentOptionsNotifier() : super(false);

  void toggleAttachmentOptions() {
    state = !state;
  }

  void closeAttachmentOptions() {
    state = false;
  }
}
