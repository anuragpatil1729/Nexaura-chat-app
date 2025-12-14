
import 'package:flutter/material.dart';
import 'package:nexaaura/models/conversation_model.dart';
import 'package:nexaaura/screens/contact_list_screen.dart';
import 'package:nexaaura/screens/group_chat_screen.dart';
import 'package:nexaaura/screens/one_to_one_chat_screen.dart';
import 'package:nexaaura/services/firestore_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("--- Building ChatScreen ---"); // Diagnostic print
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ContactListScreen(),
              ));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: firestoreService.streamConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error in ChatScreen StreamBuilder: ${snapshot.error}");
            return const Center(child: Text('An error occurred.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }

          final conversations = snapshot.data!;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final formattedTime = DateFormat.jm().format(conversation.timestamp.toDate());

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: conversation.imageUrl != null
                      ? NetworkImage(conversation.imageUrl!)
                      : null,
                  child: conversation.imageUrl == null ? const Icon(Icons.group) : null,
                ),
                title: Text(conversation.name),
                subtitle: Text(conversation.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(formattedTime),
                onTap: () {
                  print("Tapped on conversation: ${conversation.name}"); // Diagnostic print
                  if (conversation.type == ConversationType.oneToOne) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => OneToOneChatScreen(otherUser: conversation.otherUser!),
                    ));
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => GroupChatScreen(group: conversation.group!),
                    ));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
