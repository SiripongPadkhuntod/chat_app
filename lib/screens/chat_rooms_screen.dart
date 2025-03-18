import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatRoomsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colors from your scheme
  final Color bgColor = Color(0xFFFFF2F2);
  final Color lightAccent = Color(0xFFA9B5DF);
  final Color accent = Color(0xFF7886C7);
  final Color primary = Color(0xFF2D336B);

  ChatRoomsScreen({super.key});

  Future<void> _createNewChatRoom(BuildContext context) async {
    TextEditingController roomController = TextEditingController();
    TextEditingController participantsController = TextEditingController();
    bool isPrivate = false;

    await showDialog(
      context: context,
      barrierColor: primary.withOpacity(0.3),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(
              "Create New Chat Room",
              style: GoogleFonts.poppins(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roomController,
                  decoration: InputDecoration(
                    labelText: 'Room Name',
                    labelStyle: TextStyle(color: accent),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: lightAccent),
                    ),
                  ),
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
                    Text(
                      "Private Room",
                      style: TextStyle(color: primary),
                    ),
                  ],
                ),
                if (isPrivate)
                  TextField(
                    controller: participantsController,
                    decoration: InputDecoration(
                      labelText: 'Participants (comma separated emails)',
                      labelStyle: TextStyle(color: accent),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: accent, width: 2),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: lightAccent),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: accent),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (roomController.text.trim().isNotEmpty) {
                    List<String> participants = isPrivate
                        ? participantsController.text.split(',').map((e) => e.trim()).toList()
                        : [];
                    _firestore.collection('chat_rooms').add({
                      'name': roomController.text,
                      'createdAt': Timestamp.now(),
                      'isPrivate': isPrivate,
                      'participants': participants,
                    }).then((_) {
                      Navigator.of(ctx).pop();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Create",
                  style: TextStyle(color: bgColor),
                ),
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
      barrierColor: primary.withOpacity(0.3),
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Logout",
          style: GoogleFonts.poppins(
            color: primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: primary.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: accent),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              "Logout",
              style: TextStyle(color: bgColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editChatRoom(BuildContext context, String chatRoomId, String currentName) async {
    TextEditingController roomController = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      barrierColor: primary.withOpacity(0.3),
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Edit Chat Room",
          style: GoogleFonts.poppins(
            color: primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: roomController,
          decoration: InputDecoration(
            labelText: 'Room Name',
            labelStyle: TextStyle(color: accent),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accent, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: lightAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: accent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (roomController.text.trim().isNotEmpty) {
                _firestore.collection('chat_rooms').doc(chatRoomId).update({
                  'name': roomController.text,
                }).then((_) {
                  Navigator.of(ctx).pop();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              "Save",
              style: TextStyle(color: bgColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteChatRoom(BuildContext context, String chatRoomId, String chatRoomName) async {
    TextEditingController confirmController = TextEditingController();
    await showDialog(
      context: context,
      barrierColor: primary.withOpacity(0.3),
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Delete Chat Room",
          style: GoogleFonts.poppins(
            color: primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please type the chat room name to confirm deletion:",
              style: TextStyle(color: primary.withOpacity(0.8)),
            ),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                labelText: 'Chat Room Name',
                labelStyle: TextStyle(color: accent),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: accent, width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: lightAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: accent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text.trim() == chatRoomName) {
                _firestore.collection('chat_rooms').doc(chatRoomId).delete().then((_) {
                  Navigator.of(ctx).pop();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              "Delete",
              style: TextStyle(color: bgColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        title: Text(
          "Chat Rooms",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: bgColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: bgColor),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor, Color(0xFFFAF8FF)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('chat_rooms').orderBy('createdAt', descending: true).snapshots(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: lightAccent,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No chat rooms available',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: primary.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create a new chat room to get started',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              );
            }

            final chatRooms = snapshot.data!.docs;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.builder(
                itemCount: chatRooms.length,
                itemBuilder: (ctx, index) {
                  final roomName = chatRooms[index]['name'] ?? 'No Room Name';
                  final timestamp = chatRooms[index]['createdAt'] as Timestamp;
                  final date = timestamp.toDate();
                  final dateString = "${date.day}/${date.month}/${date.year}";
                  final isPrivate = chatRooms[index]['isPrivate'] ?? false;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: lightAccent.withOpacity(0.15),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      leading: CircleAvatar(
                        backgroundColor: accent,
                        child: Text(
                          roomName.isNotEmpty ? roomName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        roomName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: primary,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Created on $dateString${isPrivate ? ' (Private)' : ''}',
                        style: GoogleFonts.poppins(
                          color: accent.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: accent),
                            onPressed: () => _editChatRoom(context, chatRooms[index].id, roomName),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: accent),
                            onPressed: () => _confirmDeleteChatRoom(context, chatRooms[index].id, roomName),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: accent,
                            size: 16,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => ChatScreen(
                              chatRoomId: chatRooms[index].id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewChatRoom(context),
        backgroundColor: primary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.add, color: bgColor),
      ),
    );
  }
}