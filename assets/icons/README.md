# Icons Directory

Place your feature icons here (SVG or PNG format).

## Required Icons

### Feature Icons
- `chat.svg` - Chat/conversation icon
- `translate.svg` - Translation icon
- `security.svg` - Security/shield icon
- `keyboard.svg` - Keyboard icon
- `automation.svg` - Automation/gear icon
- `mic.svg` - Microphone icon
- `send.svg` - Send message icon
- `settings.svg` - Settings icon

### App Icon
- `app_icon.png` - Main app launcher icon (1024x1024)

## Icon Sources

You can use icons from:
1. **Material Icons** - Already available in Flutter (no files needed)
2. **Custom Icons** - Add SVG/PNG files here
3. **Icon Packs**:
   - [Flaticon](https://www.flaticon.com/)
   - [Icons8](https://icons8.com/)
   - [Heroicons](https://heroicons.com/)
   - [Feather Icons](https://feathericons.com/)

## Using Material Icons (No Files Needed)

The app currently uses Material Icons by default, so you can skip adding icon files and the app will work perfectly!

```dart
// Already used in the code
Icons.chat_bubble_outline
Icons.translate
Icons.security
Icons.keyboard
Icons.mic
Icons.send
Icons.settings
```

## Adding Custom Icons

If you want custom icons:

1. Add SVG files to this directory
2. Update `AppIcons` class in `lib/utils/constants.dart`
3. Use `flutter_svg` to load them:

```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/icons/chat.svg',
  width: 24,
  height: 24,
  color: Colors.white,
)
```

---

**Note**: The app works perfectly with Material Icons, so adding custom icons is OPTIONAL!
