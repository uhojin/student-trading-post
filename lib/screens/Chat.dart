import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late String _userId;
  late CollectionReference _messagesCollection;
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().then((value) {
      FirebaseAuth.instance.signInAnonymously().then((userCredential) {
        setState(() {
          _userId = userCredential.user!.uid;
          _messagesCollection = FirebaseFirestore.instance.collection('messages');
        });
      });
    });
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isNotEmpty) {
      await _messagesCollection.add({
        'content': content,
        'idFrom': _userId,
        'idTo': '',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      _textEditingController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (BuildContext context, AsyncSnapshot<FirebaseApp> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _messagesCollection.orderBy('timestamp').snapshots(),
                    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Something went wrong');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading...');
                      }

                      final List<QueryDocumentSnapshot> messages = snapshot.data!.docs
                          .where((doc) =>
                      //UPDATE THE aaa TO USER ID OF POST
                      (doc['idTo'] == _userId && doc['idFrom'] == "aaa") ||
                          (doc['idTo'] == "aaa" && doc['idFrom'] == _userId))
                          .toList();

                      return Expanded(
                          child: ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (BuildContext context, int index) {
                        final message = messages[index];
                        return ListTile(
                          title: Text(message['content']),
                          );
                        },
                          ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textEditingController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          _sendMessage(_textEditingController.text.trim());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
