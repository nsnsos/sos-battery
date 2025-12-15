import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

class ChatScreen extends StatefulWidget {
  final String jobId; // ID job SOS
  final bool isHero; // <-- ĐÃ THÊM: Cờ xác định người dùng hiện tại là Hero hay User

  const ChatScreen({super.key, required this.jobId, required this.isHero});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  // final String userId = FirebaseAuth.instance.currentUser!.uid; // Dễ bị lỗi nếu user chưa đăng nhập
  User? _currentUser;
  String _senderRole = 'User';

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _senderRole = widget.isHero ? 'Hero' : 'User';
  }

  void _checkUserStatus() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      // Xử lý trường hợp người dùng chưa đăng nhập (ví dụ: đăng nhập ẩn danh)
      FirebaseAuth.instance.signInAnonymously().then((userCredential) {
        setState(() {
          _currentUser = userCredential.user;
        });
      });
    }
  }


  void _sendMessage() {
    if (_controller.text.isNotEmpty && _currentUser != null) {
      FirebaseFirestore.instance
          .collection('jobs') // Giữ nguyên collection 'jobs' theo bạn
          .doc(widget.jobId)
          .collection('messages')
          .add({
        'text': _controller.text,
        'senderId': _currentUser!.uid, // <-- ĐÃ SỬA: Dùng UID thật
        'senderRole': _senderRole,    // <-- ĐÃ SỬA: Dùng Role (Hero/User)
        'timestamp': Field timestamp.now(),
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Ẩn Danh (${widget.jobId})')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .doc(widget.jobId)
                  .collection('messages')
                  .orderBy('timestamp') // Tin nhắn cũ ở trên, mới ở dưới
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final messages = snapshot.data!.docs;
                // Sử dụng ListView.builder ngược để tin nhắn mới nhất nằm ở dưới cùng
                return ListView.builder(
                  reverse: true, 
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final currentUserId = _currentUser?.uid;
                    final senderId = msg['senderId'];

                    return MessageBubble(
                      sender: msg['senderRole'] ?? 'Ẩn danh',
                      text: msg['text'] ?? '',
                      isMe: currentUserId == senderId, // So sánh với ID người dùng hiện tại
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: InputDecoration(hintText: "Gửi tin nhắn..."))),
                IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// Widget riêng để hiển thị bong bóng chat (MessageBubble)
class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;

  const MessageBubble({super.key, required this.sender, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(fontSize: 12.0, color: Colors.black54),
          ),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15.0),
              topRight: const Radius.circular(15.0),
              bottomLeft: isMe ? const Radius.circular(15.0) : const Radius.circular(0.0),
              bottomRight: isMe ? const Radius.circular(0.0) : const Radius.circular(15.0),
            ),
            elevation: 5.0,
            color: isMe ? Colors.blueAccent[100] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
