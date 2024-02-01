import 'package:chatty/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Messages extends StatelessWidget {
  const Messages({super.key});
  @override
  Widget build(BuildContext context) {
    // get the cuent authenticated user
    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    final streamOfMessages = FirebaseFirestore.instance
        .collection('messages')
        .orderBy('sendAt', descending: true)
        .snapshots();
    return StreamBuilder(
        stream: streamOfMessages,
        builder: (ctx, messagesSnapshot) {
          if (messagesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!messagesSnapshot.hasData ||
              messagesSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No Messages yet'),
            );
          }

          if (messagesSnapshot.hasError) {
            return const Center(
              child: Text('Something went wrong...'),
            );
          }

          // get the data from the snapshot
          final loadedMessages = messagesSnapshot.data!.docs;

          return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.only(bottom: 40, left: 14, right: 14),
              itemCount: loadedMessages.length,
              itemBuilder: ((ctx, index) {
                // get the previous and curfrent and next message data
                final currentMessage = loadedMessages[index].data();
                final nextMessage = index + 1 < loadedMessages.length
                    ? loadedMessages[index + 1].data()
                    : null;
                final previousMessage =
                    index - 1 >= 1 ? loadedMessages[index - 1].data() : null;

                // get the user id of the current and next message to know if it's the same user
                final currentMessageUserId = currentMessage['userId'];
                final nextMessageUserId =
                    nextMessage != null ? nextMessage['userId'] : null;

                final nextUserIsSame =
                    nextMessageUserId == currentMessageUserId;
                // get the info of the message to be displayed
                final message = currentMessage['text'];
                final userImage = currentMessage['userImage'];
                final userName = currentMessage['userName'];

                if (nextUserIsSame) {
                  return MessageBubble.next(
                    message: message,
                    isMe: currentMessageUserId == authenticatedUser.uid,
                  );
                } else {
                  return MessageBubble.first(
                    userImage: userImage,
                    username: userName,
                    message: message,
                    isMe: currentMessageUserId == authenticatedUser.uid,
                  );
                }
              }));
        });
  }
}
