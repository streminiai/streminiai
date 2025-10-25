# Stremini Chatbot Frontend

A Flutter chatbot application with a modern dark theme UI.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── chat_message.dart     # Chat message data model
├── providers/
│   ├── chat_provider.dart    # Chat state management
│   └── drawer_provider.dart  # Navigation drawer state
├── screens/
│   └── chat_screen.dart      # Main chat interface
└── widgets/
    ├── chat_input.dart       # Message input with attachments
    ├── message_bubble.dart # Individual message display
    ├── navigation_drawer.dart # Side navigation menu
    └── typing_indicator.dart # Animated typing indicator
```

## Features

- **Dark Theme UI**: Modern dark interface matching the design
- **Message Bubbles**: User and AI message display with proper styling
- **Typing Indicator**: Animated typing indicator for AI responses
- **Navigation Drawer**: Side menu with search, menu items, and chat history
- **Attachment Options**: Camera, photo, and document attachment options
- **State Management**: Flutter Riverpod for reactive state management

## Getting Started

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- `flutter_riverpod`: State management
- `cupertino_icons`: UI icons

## UI Components

- **ChatScreen**: Main chat interface with message list and input
- **MessageBubble**: Individual message display with user/AI styling
- **TypingIndicator**: Animated dots for AI typing state
- **ChatInput**: Text input with attachment options
- **NavigationDrawer**: Side menu with search and history

## State Management

The app uses Flutter Riverpod for state management:

- `ChatProvider`: Manages chat messages and typing state
- `DrawerProvider`: Controls navigation drawer visibility
- `AttachmentOptionsProvider`: Manages attachment options visibility

## Future Enhancements

- Logo integration in the header
- Chat functionality implementation
- Voice recording capabilities
- File attachment handling
- Settings screen implementation