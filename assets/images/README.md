# Images Directory

Place your app images here (PNG, JPG, or SVG format).

## Suggested Images

### Branding
- `logo.png` - App logo (transparent background)
- `logo_text.png` - App logo with text

### Onboarding (Optional)
- `onboarding_1.png` - Welcome illustration
- `onboarding_2.png` - Features illustration
- `onboarding_3.png` - Permissions illustration

### Empty States (Optional)
- `empty_chat.png` - No messages illustration
- `empty_history.png` - No history illustration
- `error_network.png` - Network error illustration

## Image Specifications

### Logo
- **Size**: 512x512px minimum
- **Format**: PNG with transparent background
- **Color**: Should work on dark backgrounds

### Illustrations
- **Size**: 200-400px width recommended
- **Format**: PNG or SVG
- **Style**: Flat design, minimal, matching dark theme

## Image Sources

Create or download illustrations from:
1. **Undraw** - https://undraw.co/illustrations
2. **Storyset** - https://storyset.com/
3. **DrawKit** - https://www.drawkit.com/
4. **Humaaans** - https://www.humaaans.com/

## Using Images in Flutter

```dart
// For local images
Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 100,
)

// For SVG
SvgPicture.asset(
  'assets/images/illustration.svg',
  width: 200,
)
```

---

**Note**: Images are OPTIONAL! The app works perfectly without them. Add images only for branding and polish.
