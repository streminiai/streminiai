# Stremini AI - Project Structure Documentation

## 📋 Overview
Stremini AI is an Android application built with Flutter that provides AI-powered features through a floating widget interface. The app uses Google Gemini AI via a Cloudflare Workers backend.

---

## 🏗️ Project Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────┐
│         Flutter Frontend (Android)               │
│  ┌──────────────────────────────────────────┐  │
│  │  Floating Widget UI                       │  │
│  │  - Chat Widget                            │  │
│  │  - Translation Overlay                    │  │
│  │  - Security Scanner                       │  │
│  │  - AI Keyboard                            │  │
│  └──────────────────────────────────────────┘  │
│                    ↕                             │
│  ┌──────────────────────────────────────────┐  │
│  │  Services Layer                           │  │
│  │  - API Service                            │  │
│  │  - Permission Service                     │  │
│  │  - Accessibility Service                  │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                     ↕
┌─────────────────────────────────────────────────┐
│      Cloudflare Workers Backend                  │
│  - Chat Endpoints                                │
│  - Automation Endpoints                          │
│  - Translation Endpoints                         │
│  - Security Endpoints                            │
│  - Keyboard Endpoints                            │
└─────────────────────────────────────────────────┘
                     ↕
┌─────────────────────────────────────────────────┐
│          Google Gemini 2.5 Flash AI              │
└─────────────────────────────────────────────────┘
```

---

## 📁 Complete Directory Structure
```
stremini-chatbot/
│
├── android/                              # Android native code
│   └── app/
│       ├── src/
│       │   └── main/
│       │       ├── kotlin/com/stremini/ai/
│       │       │   ├── MainActivity.kt          ✅ COMPLETED
│       │       │   └── ScreenReaderService.kt   ✅ COMPLETED
│       │       ├── res/
│       │       │   ├── values/
│       │       │   │   └── strings.xml          ✅ COMPLETED
│       │       │   └── xml/
│       │       │       └── accessibility_service_config.xml  ✅ COMPLETED
│       │       └── AndroidManifest.xml          ✅ COMPLETED
│       └── build.gradle                         ✅ COMPLETED
│
├── backend/                              # Cloudflare Workers backend
│   ├── routes/
│   │   ├── chat.js                      ✅ COMPLETED
│   │   ├── keyboard.js                  ✅ COMPLETED
│   │   ├── automation.js                ✅ COMPLETED
│   │   ├── security.js                  ✅ COMPLETED
│   │   └── translation.js               ✅ COMPLETED
│   ├── index.js                         ✅ COMPLETED
│   └── README.md                        ✅ COMPLETED
│
├── lib/                                  # Flutter application code
│   ├── config/
│   │   └── api_constants.dart           ✅ COMPLETED
│   │
│   ├── core/
│   │   └── permission_service.dart      ✅ COMPLETED
│   │
│   ├── models/                          ✅ COMPLETED
│   │   ├── chat_message.dart
│   │   ├── automation_action.dart
│   │   ├── security_scan_result.dart
│   │   └── keyboard_action.dart
│   │
│   ├── services/                        ✅ COMPLETED
│   │   └── stremini_api_service.dart
│   │
│   ├── features/
│   │   └── chat_provider.dart           ✅ COMPLETED
│   │
│   ├── widgets/                         🔄 IN PROGRESS
│   │   ├── common/
│   │   ├── floating_widget/             ⏳ TODO
│   │   ├── chat/                        ⏳ TODO
│   │   ├── translation/                 ⏳ TODO
│   │   ├── security/                    ⏳ TODO
│   │   └── keyboard/                    ⏳ TODO
│   │
│   ├── screens/                         ⏳ TODO
│   │   ├── home_screen.dart
│   │   ├── onboarding_screen.dart
│   │   └── settings_screen.dart
│   │
│   └── main.dart                        ⏳ TODO
│
├── assets/                              ⏳ TODO
│   ├── icons/
│   └── images/
│
├── docs/
│   ├── PROJECT_STRUCTURE.md             ✅ YOU ARE HERE
│   └── README.md
│
├── pubspec.yaml                         ✅ COMPLETED
├── .gitignore                           ✅ COMPLETED
├── LICENSE                              ✅ COMPLETED
└── README.md                            ✅ COMPLETED
```

---

## 🔧 What We've Built So Far

### ✅ Backend (100% Complete)
- **Cloudflare Workers API** with Hono.js framework
- **5 Feature Routes**:
  1. `/chat/*` - AI chatbot with streaming support
  2. `/keyboard/*` - Text completion, tone change, translation
  3. `/automation/*` - Voice command parsing
  4. `/security/*` - Content scanning, URL checking
  5. `/translation/*` - Bulk screen translation
- **Google Gemini 2.5 Flash** integration
- **CORS enabled** for cross-origin requests
- **Error handling** and logging

### ✅ Android Native (100% Complete)
- **AndroidManifest.xml** with all required permissions:
  - `SYSTEM_ALERT_WINDOW` - Floating widget overlay
  - `BIND_ACCESSIBILITY_SERVICE` - Screen content reading
  - `RECORD_AUDIO` - Voice commands
  - `INTERNET` - API communication
- **MainActivity.kt** - Main Flutter activity
- **ScreenReaderService.kt** - Accessibility service for screen reading
- **accessibility_service_config.xml** - Service configuration
- **build.gradle** - Build configuration with min SDK 23

### ✅ Flutter Data Layer (100% Complete)
- **API Configuration**: `api_constants.dart` with all endpoints
- **API Service**: `stremini_api_service.dart` with methods for all features
- **Data Models**:
  - `ChatMessage` - Chat conversation structure
  - `AutomationAction` - Parsed voice commands
  - `SecurityScanResult` - Security analysis results
  - `KeyboardAction` - Keyboard feature actions
- **Permission Service**: Runtime permission handling

---

## 🎯 What's Next (To-Do)

### 🔄 Providers/State Management
- [ ] Chat Provider (partial exists, needs completion)
- [ ] Automation Provider
- [ ] Translation Provider
- [ ] Security Provider
- [ ] Keyboard Provider
- [ ] Settings Provider

### 🎨 UI Components
- [ ] Floating Widget (draggable bubble)
- [ ] Chat Interface Widget
- [ ] Translation Overlay
- [ ] Security Scanner UI
- [ ] AI Keyboard Interface
- [ ] Feature Selection Menu

### 📱 Screens
- [ ] Onboarding/Permissions Screen
- [ ] Home/Dashboard Screen
- [ ] Settings Screen
- [ ] Feature Configuration Screens

### 🔗 Integration
- [ ] Connect UI to API services
- [ ] Implement floating overlay window
- [ ] Accessibility service integration
- [ ] Voice recognition setup
- [ ] Keyboard input method service

---

## 🚀 Key Features Implementation Status

| Feature | Backend | Models | Service | UI | Integration | Status |
|---------|---------|--------|---------|-------|-------------|--------|
| AI Chatbot | ✅ | ✅ | ✅ | ⏳ | ⏳ | 60% |
| Voice Automation | ✅ | ✅ | ✅ | ⏳ | ⏳ | 60% |
| Screen Translation | ✅ | ✅ | ✅ | ⏳ | ⏳ | 60% |
| Scam Detection | ✅ | ✅ | ✅ | ⏳ | ⏳ | 60% |
| AI Keyboard | ✅ | ✅ | ✅ | ⏳ | ⏳ | 60% |
| Floating Widget | ⏳ | N/A | ⏳ | ⏳ | ⏳ | 0% |

**Overall Progress: ~40%**

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **UI Components**: Material Design 3

### Backend
- **Platform**: Cloudflare Workers
- **Framework**: Hono.js
- **AI Model**: Google Gemini 2.5 Flash
- **API**: REST with SSE streaming

### Android Native
- **Language**: Kotlin
- **Services**: Accessibility Service, Overlay Service
- **Min SDK**: 23 (Android 6.0)
- **Target SDK**: 34 (Android 14)

---

## 📦 Dependencies
```yaml
# Flutter (pubspec.yaml)
http: ^1.1.0                    # API calls
provider: ^6.1.1                # State management
flutter_overlay_window: ^0.4.6  # Floating widget
speech_to_text: ^6.6.0          # Voice recognition
permission_handler: ^11.1.0     # Runtime permissions
flutter_svg: ^2.0.9             # SVG icons
animations: ^2.0.11             # UI animations
```

---

## 🔐 Security & Privacy

- ✅ **No data storage** - All processing is stateless
- ✅ **Secure API** - HTTPS only
- ✅ **Permission transparency** - Clear explanations for each permission
- ✅ **Local processing** - Screen content sent to backend only when requested
- ✅ **No tracking** - No analytics or user tracking

---

## 📝 API Endpoints Reference

### Chat
- `POST /chat/message` - Send message, get response
- `POST /chat/stream` - Streaming chat (SSE)
- `GET /chat/suggestions` - Get suggestion prompts

### Keyboard
- `POST /keyboard/complete` - Auto-complete text
- `POST /keyboard/tone` - Change text tone
- `POST /keyboard/translate` - Translate text

### Automation
- `POST /automation/voice-command` - Parse voice command

### Security
- `POST /security/scan-content` - Scan for threats
- `POST /security/check-url` - Validate URL

### Translation
- `POST /translation/translate-screen` - Translate screen content

---

## 🤝 Contributing

This is the current development branch: `flutter-app-development`

Next steps for contributors:
1. UI Components implementation
2. State management setup
3. Feature integration
4. Testing & debugging

---

## 📄 License

MIT License - See LICENSE file for details

---

**Last Updated**: November 2025  
**Current Branch**: flutter-app-development  
**Next Milestone**: Floating widget implementation
