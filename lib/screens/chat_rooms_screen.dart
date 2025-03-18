import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';

class ChatRoomsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChatRoomsScreen({super.key});

  Future<void> _createNewChatRoom(BuildContext context) async {
    TextEditingController roomController = TextEditingController();
    TextEditingController participantsController = TextEditingController();
    bool isPrivate = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Create New Chat Room"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roomController,
                  decoration: InputDecoration(labelText: 'Room Name'),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: isPrivate,
                      onChanged: (value) {
                        setState(() {
                          isPrivate = value!;
                        });
                      },
                    ),
                    Text("Private Room"),
                  ],
                ),
                if (isPrivate)
                  TextField(
                    controller: participantsController,
                    decoration: InputDecoration(labelText: 'Participants (comma separated emails)'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (roomController.text.trim().isNotEmpty) {
                    List<String> participants = isPrivate
                        ? participantsController.text.split(',').map((e) => e.trim()).toList()
                        : [];
                    
                    // Add creator to participants list for private rooms
                    if (isPrivate && _auth.currentUser != null) {
                      participants.add(_auth.currentUser!.email ?? '');
                    }
                    
                    _firestore.collection('chat_rooms').add({
                      'name': roomController.text,
                      'createdAt': Timestamp.now(),
                      'isPrivate': isPrivate,
                      'participants': participants,
                      'createdBy': _auth.currentUser?.uid ?? '',
                    }).then((_) {
                      Navigator.of(ctx).pop();
                    });
                  }
                },
                child: Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }

  Future<void> _editChatRoom(BuildContext context, String chatRoomId, String currentName, List<String> currentParticipants, bool isPrivate) async {
    TextEditingController roomController = TextEditingController(text: currentName);
    TextEditingController participantsController = TextEditingController(
      text: currentParticipants.join(', ')
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit Chat Room"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roomController,
              decoration: InputDecoration(labelText: 'Room Name'),
            ),
            if (isPrivate) ...[
              SizedBox(height: 10),
              TextField(
                controller: participantsController,
                decoration: InputDecoration(labelText: 'Participants (comma separated emails)'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (roomController.text.trim().isNotEmpty) {
                Map<String, dynamic> updateData = {
                  'name': roomController.text,
                };
                
                if (isPrivate) {
                  List<String> participants = participantsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  
                  // Ensure creator is always in the list
                  String? creatorEmail = _auth.currentUser?.email;
                  if (creatorEmail != null && !participants.contains(creatorEmail)) {
                    participants.add(creatorEmail);
                  }
                  
                  updateData['participants'] = participants;
                }
                
                _firestore.collection('chat_rooms')
                  .doc(chatRoomId)
                  .update(updateData)
                  .then((_) {
                    Navigator.of(ctx).pop();
                  });
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteChatRoom(BuildContext context, String chatRoomId, String chatRoomName) async {
    TextEditingController confirmController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Chat Room"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Please type the chat room name to confirm deletion:"),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(labelText: 'Chat Room Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text.trim() == chatRoomName) {
                _firestore.collection('chat_rooms').doc(chatRoomId).delete().then((_) {
                  Navigator.of(ctx).pop();
                });
              }
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _manageParticipants(BuildContext context, String chatRoomId, List<String> currentParticipants) async {
    TextEditingController participantsController = TextEditingController(
      text: currentParticipants.join(', ')
    );
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Manage Participants"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Add or remove participants (comma separated emails):"),
            SizedBox(height: 8),
            TextField(
              controller: participantsController,
              decoration: InputDecoration(labelText: 'Participants'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              List<String> participants = participantsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              
              // Ensure creator is always in the list
              String? creatorEmail = _auth.currentUser?.email;
              if (creatorEmail != null && !participants.contains(creatorEmail)) {
                participants.add(creatorEmail);
              }
              
              _firestore.collection('chat_rooms')
                .doc(chatRoomId)
                .update({
                  'participants': participants,
                }).then((_) {
                  Navigator.of(ctx).pop();
                });
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserEmail = _auth.currentUser?.email;
    final String currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Rooms"),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('chat_rooms').orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80),
                  SizedBox(height: 16),
                  Text('No chat rooms available'),
                  SizedBox(height: 8),
                  Text('Create a new chat room to get started'),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data!.docs;
          
          // Filter rooms - only show public rooms or private rooms where user is a participant
          final filteredRooms = chatRooms.where((room) {
            bool isPrivate = room['isPrivate'] ?? false;
            if (!isPrivate) return true;
            
            List<String> participants = List<String>.from(room['participants'] ?? []);
            String createdBy = room['createdBy'] ?? '';
            
            return !isPrivate || 
                   createdBy == currentUserId || 
                   (currentUserEmail != null && participants.contains(currentUserEmail));
          }).toList();
          
          if (filteredRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80),
                  SizedBox(height: 16),
                  Text('No chat rooms available'),
                  SizedBox(height: 8),
                  Text('Create a new chat room to get started'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredRooms.length,
            itemBuilder: (ctx, index) {
              final roomName = filteredRooms[index]['name'] ?? 'No Room Name';
              final timestamp = filteredRooms[index]['createdAt'] as Timestamp;
              final date = timestamp.toDate();
              final dateString = "${date.day}/${date.month}/${date.year}";
              final isPrivate = filteredRooms[index]['isPrivate'] ?? false;
              final isCreator = filteredRooms[index]['createdBy'] == currentUserId;
              final List<String> participants = List<String>.from(filteredRooms[index]['participants'] ?? []);

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    roomName.isNotEmpty ? roomName[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(roomName),
                subtitle: Text('Created on $dateString${isPrivate ? ' (Private)' : ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPrivate)
                      IconButton(
                        icon: Icon(Icons.people),
                        onPressed: () => _manageParticipants(
                          context, 
                          filteredRooms[index].id, 
                          participants
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editChatRoom(
                        context, 
                        filteredRooms[index].id, 
                        roomName,
                        participants,
                        isPrivate
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _confirmDeleteChatRoom(
                        context, 
                        filteredRooms[index].id, 
                        roomName
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ChatScreen(
                        chatRoomId: filteredRooms[index].id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewChatRoom(context),
        child: Icon(Icons.add),
      ),
    );
  }
}