import 'package:flutter/material.dart';
import 'package:stremini_chatbot/widgets/drawer_widgets/app_drawer.dart';
import 'package:stremini_chatbot/widgets/chat_body.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // adjusts for keyboard height
      drawer: const AppDrawer(),
      appBar: const ChatAppBar(),
      body: Column(
        children: [
          Expanded(child: ChatBody()),
          const MessageInput(),
        ],
      ),
    );
  }
}
