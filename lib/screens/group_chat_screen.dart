
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexaaura/models/group_model.dart' as group_model;
import 'package:nexaaura/services/storage_service.dart';
import 'package:nexaaura/theme.dart';
import 'package:nexaaura/widgets/audio_message_bubble.dart';

class GroupChatScreen extends StatefulWidget {
  final group_model.Group group;

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  void _handleSubmitted(String text) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (text.isNotEmpty && currentUser != null) {
      FirebaseFirestore.instance.collection('groups').doc(widget.group.id).collection('messages').add({
        'text': text,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? currentUser.email,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });
      _textController.clear();
    }
  }

  Future<void> _sendImage() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final String imageUrl = await _storageService.uploadImage(File(image.path));
      FirebaseFirestore.instance.collection('groups').doc(widget.group.id).collection('messages').add({
        'imageUrl': imageUrl,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? currentUser.email,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("--- Building GroupChatScreen ---"); // Diagnostic print
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text("Error: No user logged in."));
          }
          final currentUser = userSnapshot.data!;

          return Column(
            children: [
              Flexible(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.group.id)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final documents = snapshot.data?.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      reverse: true,
                      itemCount: documents?.length ?? 0,
                      itemBuilder: (_, int index) {
                        final data = documents?[index].data();
                        if (data != null) {
                          final isMe = data['senderId'] == currentUser.uid;
                          return _buildMessage(data, isMe);
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1.0),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo),
              onPressed: _sendImage,
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(hintText: 'Send a message'),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> data, bool isMe) {
    final messageContent = Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              data['senderName'] ?? 'Someone',
              style: const TextStyle(fontSize: 12.0, color: neonCyan, fontWeight: FontWeight.bold),
            ),
          ),
        if (data['type'] == 'text')
          Text(data['text'] ?? '', style: const TextStyle(fontSize: 16)),
        if (data['type'] == 'image')
          Image.network(data['imageUrl'], width: 200),
        // Voice messages can be added here as well
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? darkGrey : lightGrey.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: isMe ? neonMagenta.withOpacity(0.4) : neonCyan.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: messageContent,
          ),
        ],
      ),
    );
  }
}
