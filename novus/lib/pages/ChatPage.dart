import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/ChatScreen.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController newChatName = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        elevation: 8,
        title: GradientText(
          "Groups",
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor,
            ],
          ),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 25.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => newChat(context),
            child: Row(
              children: [
                Text(
                  "New group",
                  style: TextStyle(color: Theme.of(context).accentColor, fontSize: 19),
                ),
                Icon(
                  CupertinoIcons.add,
                  color: Theme.of(context).accentColor,
                  size: 30,
                )
              ],
            ),
          )
        ],
      ),
      body: StreamBuilder(
        stream: chatReference.where("members", arrayContains: user.id).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return circularProgress();
          List<ChatTiles> temp = [];
          snapshot.data.docs.forEach((element) {
            temp.add(ChatTiles.fromDocument(element));
          });
          return ListView(
            children: temp,
          );
        },
      ),
    );
  }

  newChat(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        bool _chatName = true;
        return StatefulBuilder(
          builder: (context, setState) {
            return SimpleDialog(
              contentPadding: EdgeInsets.all(0.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              backgroundColor: Colors.grey[900],
              title: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Container(
                  width: double.maxFinite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Group details",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: newChatName,
                          decoration: InputDecoration(
                            labelText: "Name",
                            labelStyle: TextStyle(color: Colors.white),
                            hintText: "Provide a name",
                            hintStyle: TextStyle(color: Colors.white38),
                            errorText: !_chatName ? "name required" : null,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          cursorColor: Colors.white,
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              children: <Widget>[
                Container(
                  height: 0.10,
                  color: Colors.white,
                ),
                SimpleDialogOption(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        "Done",
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 17.0,
                        ),
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(
                      () {
                        if (newChatName.text.isEmpty) {
                          _chatName = false;
                        } else {
                          _chatName = true;
                        }
                      },
                    );

                    if (_chatName) {
                      var df = chatReference.doc();
                      chatReference.doc(df.id).set({
                        'chatId': df.id,
                        'members': [user.id],
                        'name': newChatName.text,
                        'chatUrl': "",
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
                Container(
                  height: 0.10,
                  color: Colors.white,
                ),
                SimpleDialogOption(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.0,
                        ),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
        );
      },
    );
  }
}

class ChatTiles extends StatefulWidget {
  final String chatUrl;
  final String name;
  final String chatId;
  final List members;

  ChatTiles({
    this.chatUrl,
    this.name,
    this.chatId,
    this.members,
  });

  factory ChatTiles.fromDocument(DocumentSnapshot doc) {
    return ChatTiles(
      chatId: doc.data()['chatId'],
      name: doc.data()['name'],
      members: doc.data()['members'],
      chatUrl: doc.data()['chatUrl'],
    );
  }

  @override
  _ChatTilesState createState() => _ChatTilesState(
        chatId: this.chatId,
        name: this.name,
        chatPhotoUrl: this.chatUrl,
        members: this.members,
      );
}

class _ChatTilesState extends State<ChatTiles> {
  String chatPhotoUrl;
  String name;
  String chatId;
  List members;
  String lastMessage;
  Timestamp lastTime;

  _ChatTilesState({
    this.chatPhotoUrl,
    this.name,
    this.chatId,
    this.members,
  });

  @override
  void initState() {
    getLastMessage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => pushNewScreen(
        context,
        screen: ChatScreen(
          chatUrl: chatPhotoUrl,
          user: user,
          chatId: chatId,
        ),
        withNavBar: false, // OPTIONAL VALUE. True by default.
        pageTransitionAnimation: PageTransitionAnimation.fade,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(2),
              // decoration: chat.unread
              //     ? BoxDecoration(
              //         borderRadius: BorderRadius.all(Radius.circular(40)),
              //         border: Border.all(
              //           width: 2,
              //           color: Theme.of(context).primaryColor,
              //         ),
              //       )
              //     : BoxDecoration(
              //         shape: BoxShape.circle,
              //       ),
              child: CircleAvatar(
                radius: 35,
                backgroundImage: chatPhotoUrl == "" ? null : CachedNetworkImageProvider(chatPhotoUrl),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.65,
              padding: EdgeInsets.only(
                left: 20,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // chat.sender.isOnline
                          //     ? Container(
                          //         margin: const EdgeInsets.only(left: 5),
                          //         width: 7,
                          //         height: 7,
                          //         decoration: BoxDecoration(
                          //           shape: BoxShape.circle,
                          //           color: Theme.of(context).primaryColor,
                          //         ),
                          //       )
                          //     : Container(
                          //         child: null,
                          //       ),
                        ],
                      ),
                      Text(
                        lastTime == null ? "" : timeago.format(lastTime.toDate()),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      lastMessage == null ? "" : lastMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void getLastMessage() async {
    String temp;
    Timestamp tempTime;
    await chatReference
        .doc(chatId)
        .collection('messages')
        .orderBy('time', descending: true)
        .get()
        .then((value) => value.docs.first.exists ? temp = value.docs.first.data()['message'] : null)
        .onError((error, stackTrace) => null);

    await chatReference
        .doc(chatId)
        .collection('messages')
        .orderBy('time', descending: true)
        .get()
        .then((value) => value.docs.first.exists ? tempTime = value.docs.first.data()['time'] : null)
        .onError((error, stackTrace) => null);
    setState(() {
      lastMessage = temp;
      lastTime = tempTime;
    });
  }
}
