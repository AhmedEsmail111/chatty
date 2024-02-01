import 'package:chatty/widgets/messages.dart';
import 'package:chatty/widgets/new_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  // a method to set up the firebase push notifications
  void _setUpPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    // request the permission of the user to send him notifications
    await fcm.requestPermission();

    // subscribe all device to the same topic so all notificayions go to all devices
    fcm.subscribeToTopic('chat');
  }

  @override
  void initState() {
    super.initState();

    _setUpPushNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatty'),
        actions: [
          IconButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              icon: Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.primary,
              ))
        ],
      ),
      body: const Column(
        children: [
          Expanded(
            child: Messages(),
          ),
          NewMessage(),
        ],
      ),
    );
  }
}
