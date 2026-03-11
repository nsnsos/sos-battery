import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: unused_import
import 'package:sos_battery/features/sos/presentation/pages/chat_screen.dart';

class ChatScreen extends StatefulWidget {
  final String sosId;
  final String driverId;

  const ChatScreen({super.key, required this.sosId, required this.driverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('sos_requests')
        .doc(widget.sosId)
        .collection('messages')
        .add({
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();

    // Auto scroll xuống tin nhắn mới
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final bool isHero = currentUserId != widget.driverId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isHero ? 'Chat with Driver' : 'Chat with Hero'),
        backgroundColor: Colors.green[800],
      ),
      body: Column(
        children: [
          // List messages realtime
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sos_requests')
                  .doc(widget.sosId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.green));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentUserId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[700] : Colors.grey[700],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          msg['message'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input message
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(), // Gửi bằng Enter
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
