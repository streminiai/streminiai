// Add this to your existing home_screen.dart

// Update the Smart Chatbot card to have two actions:

_buildFeatureCard(
  title: 'Smart Chatbot',
  description: 'Multi-language assistant with voice support & safety tips',
  icon: Icons.chat_bubble_outline,
  iconColor: const Color(0xFF23A6E2),
  status: 'online 24/7',
  statusColor: Colors.green,
  badges: const ['Safety Tips', 'Multi-language'],
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Floating Chat Button
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF25D366),
            width: 2,
          ),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.chat_bubble_rounded,
            size: 20,
            color: Color(0xFF25D366),
          ),
          padding: EdgeInsets.zero,
          onPressed: () {
            // Show floating chat
            ref.read(enhancedFloatingChatProvider.notifier).show();
          },
        ),
      ),
      const SizedBox(width: 8),
      // Full Screen Chat Button
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF23A6E2).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF23A6E2),
            width: 2,
          ),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.fullscreen,
            size: 20,
            color: Color(0xFF23A6E2),
          ),
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          },
        ),
      ),
    ],
  ),
  onTap: null, // Disable tap since we have buttons
),

// Don't forget to add this import at the top:
// import '../widgets/whatsapp_floating_chat.dart';
