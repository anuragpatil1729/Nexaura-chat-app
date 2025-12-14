
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nexaaura/models/user_model.dart';
import 'package:nexaaura/services/audio_service.dart';
import 'package:nexaaura/services/firestore_service.dart';
import 'package:nexaaura/services/storage_service.dart';
import 'package:nexaaura/theme.dart';
import 'package:nexaaura/widgets/audio_message_bubble.dart';

class OneToOneChatScreen extends StatefulWidget {
  final AppUser otherUser;

  const OneToOneChatScreen({super.key, required this.otherUser});

  @override
  State<OneToOneChatScreen> createState() => _OneToOneChatScreenState();
}

class _OneToOneChatScreenState extends State<OneToOneChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final AudioService _audioService = AudioService();
  final FirestoreService _firestoreService = FirestoreService();
  late final String _chatRoomId;
  late final User _currentUser;
  Timer? _typingTimer;
  bool _isRecording = false;
  bool _showSendButton = false;
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    final uids = [_currentUser.uid, widget.otherUser.uid]..sort();
    _chatRoomId = uids.join('_');
    _audioService.initialize();
    _textController.addListener(() {
      setState(() {
        _showSendButton = _textController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _typingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(Map<String, dynamic> messageData) async {
    final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(_chatRoomId);
    final messageCollection = chatDocRef.collection('messages');

    await chatDocRef.set({
      'participants': [_currentUser.uid, widget.otherUser.uid],
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await messageCollection.add(messageData);

    if (_replyingTo != null) {
      setState(() {
        _replyingTo = null;
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      final messageData = {
        'text': text,
        'senderId': _currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'isRead': false,
        'replyTo': _replyingTo,
        'reactions': {},
      };
      _sendMessage(messageData);
      _textController.clear();
    }
  }

  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final String imageUrl = await _storageService.uploadImage(File(image.path));
      final messageData = {
        'imageUrl': imageUrl,
        'senderId': _currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
        'isRead': false,
        'reactions': {},
      };
      _sendMessage(messageData);
    }
  }

  Future<void> _sendAudio(String path) async {
    final String audioUrl = await _storageService.uploadImage(File(path));
    final messageData = {
      'audioUrl': audioUrl,
      'senderId': _currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'audio',
      'isRead': false,
      'reactions': {},
    };
    _sendMessage(messageData);
  }

  void _markAsRead(String messageId) {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  void _startReply(Map<String, dynamic> message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _addReaction(String messageId, String emoji) {
    _firestoreService.toggleMessageReaction(
      messageId: messageId,
      chatId: _chatRoomId,
      emoji: emoji,
      isGroupChat: false,
    );
  }

  void _showReactionsDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkGrey,
        title: const Text('React to message', style: TextStyle(color: neonCyan)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['❤️', '👍', '😂', '😢', '😮'].map((emoji) {
            return IconButton(
              icon: Text(emoji, style: const TextStyle(fontSize: 32)),
              onPressed: () {
                _addReaction(messageId, emoji);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('presence').doc(widget.otherUser.uid).snapshots(),
          builder: (context, snapshot) {
            String status = 'offline';
            String lastSeen = '...';
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              status = data['status'];
              if (data['last_seen'] != null) {
                final timestamp = data['last_seen'] as Timestamp;
                lastSeen = DateFormat.yMd().add_jm().format(timestamp.toDate());
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUser.displayName ?? widget.otherUser.email ?? 'Chat'),
                Text(
                  status == 'online' ? 'online' : 'last seen $lastSeen',
                  style: const TextStyle(fontSize: 12.0, color: Colors.white70),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatRoomId)
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
                    final doc = documents?[index];
                    final data = doc?.data() as Map<String, dynamic>?;
                    if (data != null) {
                      final isMe = data['senderId'] == _currentUser.uid;
                      if (!isMe && !(data['isRead'] as bool? ?? false)) {
                        _markAsRead(doc!.id);
                      }
                      return Slidable(
                        key: ValueKey(doc!.id),
                        startActionPane: ActionPane(
                          motion: const BehindMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) => _startReply(data),
                              backgroundColor: neonCyan,
                              foregroundColor: Colors.black,
                              icon: Icons.reply,
                              label: 'Reply',
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onLongPress: () => _showReactionsDialog(doc!.id),
                          child: _buildMessage(data, isMe),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          if (_replyingTo != null) _buildReplyContextBox(),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyContextBox() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        border: const Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyingTo!['senderId'] == _currentUser.uid ? 'yourself' : widget.otherUser.displayName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _replyingTo!['text'] ?? 'an image or audio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelReply,
          )
        ],
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
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Send a message',
                ),
              ),
            ),
            if (_showSendButton)
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              )
            else
              GestureDetector(
                onLongPressStart: (_) async {
                  await _audioService.startRecording();
                  setState(() => _isRecording = true);
                },
                onLongPressEnd: (_) async {
                  final path = await _audioService.stopRecording();
                  if (path != null) {
                    _sendAudio(path);
                  }
                  setState(() => _isRecording = false);
                },
                child: Icon(_isRecording ? Icons.mic_off : Icons.mic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> data, bool isMe) {
    final replyTo = data['replyTo'];
    final reactions = Map<String, String>.from(data['reactions'] ?? {});

    final messageContent = Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (replyTo != null)
          Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              color: (isMe ? neonMagenta : neonCyan).withOpacity(0.2),
              borderRadius: const BorderRadius.all(Radius.circular(0)),
            ),
            child: Text(replyTo['text'] ?? '...', style: const TextStyle(fontStyle: FontStyle.italic, color: lightGrey)),
          ),
        if (data['type'] == 'text')
          Text(data['text'] ?? '', style: const TextStyle(fontSize: 16)),
        if (data['type'] == 'image')
          Image.network(data['imageUrl'], width: 200),
        if (data['type'] == 'audio')
          AudioMessageBubble(audioUrl: data['audioUrl'] ?? ''),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
          if (reactions.isNotEmpty) _buildReactionsDisplay(reactions),
        ],
      ),
    );
  }

  Widget _buildReactionsDisplay(Map<String, String> reactions) {
    // Count the occurrences of each emoji
    final reactionCounts = <String, int>{};
    for (final emoji in reactions.values) {
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactionCounts.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(right: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4.0),
                Text(entry.value.toString(), style: const TextStyle(fontSize: 12.0, color: lightGrey)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
