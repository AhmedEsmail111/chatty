import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// a global var for initializing a firebase fireStore database object
final _firebaseFireStore = FirebaseFirestore.instance;
// a global var for initializing a firebase auth object
final _kFirebaseAuth = FirebaseAuth.instance;

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});
  @override
  State<NewMessage> createState() {
    return _NewMessageState();
  }
}

class _NewMessageState extends State<NewMessage> {
  // a controller for the textField
  final _messageController = TextEditingController();

  // a method to validate then send the message to firebase and clear the field
  void _submitMessage() async {
    final enteredMessage = _messageController.text;
    if (enteredMessage.trim().isEmpty) {
      return;
    }
    // clear the field
    _messageController.clear();
    FocusScope.of(context).unfocus();
    // get the current user
    final user = _kFirebaseAuth.currentUser!;
    // get the data stored for the current user
    final userData =
        await _firebaseFireStore.collection('users').doc(user.uid).get();

    //send the message to fire store with related data
    _firebaseFireStore.collection('messages').add(
      {
        'userId': user.uid,
        'text': enteredMessage,
        'sendAt': DateTime.now(),
        'userImage': userData.data()!['userImage'],
        'userName': userData.data()!['userName'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 1, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'send a message...'),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            onPressed: _submitMessage,
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        ],
      ),
    );
  }
}
