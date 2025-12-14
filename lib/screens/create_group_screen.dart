
import 'package:flutter/material.dart';
import 'package:nexaaura/models/user_model.dart';
import 'package:nexaaura/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexaaura/models/group_model.dart' as group_model;

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _groupNameController = TextEditingController();
  final List<AppUser> _selectedUsers = [];

  void _toggleUserSelection(AppUser user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name and select at least one member.')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser!;
    final memberIds = [currentUser.uid, ..._selectedUsers.map((user) => user.uid)];
    
    final newGroup = group_model.Group(
      id: ' ', // will be set by firestore
      name: _groupNameController.text,
      members: memberIds.toSet().toList(), // remove duplicates
      createdBy: currentUser.uid,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance.collection('groups').add(newGroup.toMap());

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    print("--- Building CreateGroupScreen ---"); // Diagnostic print
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createGroup,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _firestoreService.streamUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final users = snapshot.data!;
                final currentUser = FirebaseAuth.instance.currentUser;
                final otherUsers = users.where((user) => user.uid != currentUser!.uid).toList();

                return ListView.builder(
                  itemCount: otherUsers.length,
                  itemBuilder: (context, index) {
                    final user = otherUsers[index];
                    final isSelected = _selectedUsers.contains(user);
                    return CheckboxListTile(
                      title: Text(user.displayName ?? user.email ?? 'No Name'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleUserSelection(user);
                      },
                      secondary: CircleAvatar(
                        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                        child: user.photoUrl == null ? const Icon(Icons.person) : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
