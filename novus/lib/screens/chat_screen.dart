import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:novus/models/message_model.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final User user;
  final String chatId;

  ChatScreen({this.user, this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String prevUserId;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        centerTitle: true,
        title: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                  text: widget.user.userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  )),
              TextSpan(text: '\n'),
              // widget.user.isOnline
              //     ? TextSpan(
              //         text: 'Online',
              //         style: TextStyle(
              //           fontSize: 11,
              //           fontWeight: FontWeight.w400,
              //         ),
              //       )
              //     : TextSpan(
              //         text: 'Offline',
              //         style: TextStyle(
              //           fontSize: 11,
              //           fontWeight: FontWeight.w400,
              //         ),
              //       )
            ],
          ),
        ),
      ),
      body: StreamBuilder(
        stream: chatReference.doc(widget.chatId).collection('messages').orderBy('time', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return circularProgress();
          List<Message> msgs = [];
          snapshot.data.docs.forEach((element) {
            msgs.add(Message.fromDocument(element));
          });
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(20),
                  itemCount: msgs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Message message = msgs[index];
                    final bool isMe = message.sender == widget.user.id;
                    final bool isSameUser = prevUserId == message.sender;
                    prevUserId = message.sender;
                    return _chatBubble(message, isMe, isSameUser);
                  },
                ),
              ),
              _sendMessageArea(),
            ],
          );
        },
      ),
    );
  }

  _chatBubble(Message message, bool isMe, bool isSameUser) {
    if (isMe) {
      return Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          !isSameUser
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        timeago.format(message.time.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundImage: CachedNetworkImageProvider(user.url),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  child: null,
                ),
        ],
      );
    } else {
      return Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          !isSameUser
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 3),
                  child: Row(
                    children: <Widget>[
                      Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: StreamBuilder(
                            stream: userReference.doc(message.sender).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return CircleAvatar(
                                  radius: 15,
                                  backgroundImage: null,
                                );
                              }
                              User user = User.fromDocument(snapshot.data);
                              return CircleAvatar(
                                radius: 15,
                                backgroundImage: CachedNetworkImageProvider(user.url),
                              );
                            },
                          )),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        timeago.format(message.time.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  child: null,
                ),
        ],
      );
    }
  }

  _sendMessageArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      height: 70,
      color: Colors.black,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            iconSize: 25,
            color: Theme.of(context).accentColor,
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration.collapsed(
                hintStyle: TextStyle(color: Colors.white),
                hintText: 'Send a message..',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25,
            color: Theme.of(context).accentColor,
            onPressed: () {
              sendMessage();
              messageController.clear();
            },
          ),
        ],
      ),
    );
  }

  sendMessage() {
    DateTime time = DateTime.now();
    var df = chatReference.doc(widget.chatId).collection('messages').doc();
    chatReference.doc(widget.chatId).collection('messages').doc().set({
      'messageId': df.id,
      'senderId': user.id,
      'time': time,
      'message': messageController.text,
    });
  }
}
