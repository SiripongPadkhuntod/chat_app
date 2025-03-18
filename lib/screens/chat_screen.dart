import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatScreen({super.key, required this.chatRoomId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Colors from your scheme
  final Color bgColor = Color(0xFFFFF2F2);
  final Color lightAccent = Color(0xFFA9B5DF);
  final Color accent = Color(0xFF7886C7);
  final Color primary = Color(0xFF2D336B);
  
  String _roomName = "Chat Room";
  
  @override
  void initState() {
    super.initState();
    _loadRoomDetails();
  }
  
  void _loadRoomDetails() async {
    try {
      DocumentSnapshot roomDoc = await _firestore.collection('chat_rooms').doc(widget.chatRoomId).get();
      if (roomDoc.exists && roomDoc.data() != null) {
        Map<String, dynamic> roomData = roomDoc.data() as Map<String, dynamic>;
        setState(() {
          _roomName = roomData['name'] ?? "Chat Room";
        });
      }
    } catch (e) {
      print('Error loading room details: $e');
    }
  }

  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('chat_rooms').doc(widget.chatRoomId).collection('messages').add({
          'text': message,
          'senderId': user.uid,
          'senderName': user.displayName ?? 'Unknown',
          'senderPhotoUrl': user.photoURL ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });

        _messageController.clear();
        
        // Scroll to bottom after sending message
        Future.delayed(Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    
    if (dateTime.day == now.day && 
        dateTime.month == now.month && 
        dateTime.year == now.year) {
      return DateFormat('h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  Widget _buildMessageBubble(DocumentSnapshot messageData, bool isSentByMe) {
    final timestamp = messageData['timestamp'] as Timestamp?;
    final timeString = _formatTimestamp(timestamp);
    
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSentByMe ? primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isSentByMe ? 16 : 4),
            topRight: Radius.circular(isSentByMe ? 4 : 16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: lightAccent.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSentByMe) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: accent,
                    backgroundImage: _getProfileImage(messageData['senderPhotoUrl']),
                    child: _getProfileImage(messageData['senderPhotoUrl']) == null
                        ? Text(
                            messageData['senderName']?.isNotEmpty == true 
                                ? messageData['senderName'][0].toUpperCase() 
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 8),
                  Text(
                    messageData['senderName'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: accent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
            ],
            Text(
              messageData['text'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isSentByMe ? Colors.white : primary.withOpacity(0.85),
              ),
            ),
            SizedBox(height: 2),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeString,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isSentByMe 
                    ? Colors.white.withOpacity(0.7)
                    : accent.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  ImageProvider? _getProfileImage(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      return NetworkImage(url);
    } catch (e) {
      return null;
    }
  }
  
  Widget _buildDateSeparator(String date) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: lightAccent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          date,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: primary.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  String _getDateString(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    
    if (dateTime.day == now.day && 
        dateTime.month == now.month && 
        dateTime.year == now.year) {
      return 'Today';
    } else if (dateTime.day == now.day - 1 && 
        dateTime.month == now.month && 
        dateTime.year == now.year) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        title: Text(
          _roomName,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: bgColor,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: bgColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bgColor, Color(0xFFFAF8FF)],
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chat_rooms')
                    .doc(widget.chatRoomId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 72,
                            color: lightAccent,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: primary.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start the conversation now!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;
                  
                  // Attach scroll controller after messages are loaded
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                    }
                  });
                  
                  // Group messages by date
                  Map<String, List<DocumentSnapshot>> groupedMessages = {};
                  
                  for (var message in messages) {
                    Timestamp? timestamp = message['timestamp'] as Timestamp?;
                    String dateString = _getDateString(timestamp);
                    
                    if (!groupedMessages.containsKey(dateString)) {
                      groupedMessages[dateString] = [];
                    }
                    
                    groupedMessages[dateString]!.add(message);
                  }
                  
                  List<Widget> messageWidgets = [];
                  groupedMessages.forEach((date, messageDocs) {
                    messageWidgets.add(_buildDateSeparator(date));
                    
                    for (var message in messageDocs) {
                      bool isSentByMe = message['senderId'] == _auth.currentUser!.uid;
                      messageWidgets.add(_buildMessageBubble(message, isSentByMe));
                    }
                  });

                  return ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    children: messageWidgets,
                  );
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: lightAccent.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: lightAccent, width: 1),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(
                          color: accent.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    splashRadius: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}