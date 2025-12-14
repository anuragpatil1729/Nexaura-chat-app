
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexaaura/models/user_model.dart';
import 'package:nexaaura/screens/create_group_screen.dart';
import 'package:nexaaura/screens/one_to_one_chat_screen.dart';
import 'package:nexaaura/services/firestore_service.dart';

class ContactListScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  ContactListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("--- Building ContactListScreen ---"); // Diagnostic print
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const CreateGroupScreen(),
          ));
        },
        child: const Icon(Icons.group_add),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _firestoreService.streamUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('presence').doc(user.uid).snapshots(),
                  builder: (context, presenceSnap) {
                    bool isOnline = false;
                    if (presenceSnap.hasData && presenceSnap.data!.exists) {
                      final data = presenceSnap.data!.data() as Map<String, dynamic>;
                      isOnline = data['status'] == 'online';
                    }
                    return Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null ? const Icon(Icons.person) : null,
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                title: Text(user.displayName ?? user.email ?? 'No Name'),
                subtitle: Text(user.email ?? ''),
                onTap: () {
                   print("Tapped on user: ${user.displayName}"); // Diagnostic print
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => OneToOneChatScreen(otherUser: user),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
