import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:novus/models/user.dart';

class Message {
  final String sender;
  final Timestamp time;
  final String text;
  final bool unread;

  Message({
    this.sender,
    this.time,
    this.text,
    this.unread,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message(
      sender: doc.data()['senderId'],
      time: doc.data()['time'],
      text: doc.data()['message'],
      unread: true,
    );
  }
}
