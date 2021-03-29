import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/screens/chat_screen.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        elevation: 8,
        title: Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
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
}

class ChatTiles extends StatefulWidget {
  final String chatPhotoUrl;
  final String name;
  final String chatId;

  ChatTiles({
    this.chatPhotoUrl,
    this.name,
    this.chatId,
  });

  factory ChatTiles.fromDocument(DocumentSnapshot doc) {
    return ChatTiles(
      chatId: doc.data()['chatId'],
      name: doc.data()['name'],
      // chatPhotoUrl: doc.data()['chatPhotoUrl'],
    );
  }

  @override
  _ChatTilesState createState() => _ChatTilesState(
        chatId: this.chatId,
        name: this.name,
        chatPhotoUrl: this.chatPhotoUrl,
      );
}

class _ChatTilesState extends State<ChatTiles> {
  String chatPhotoUrl;
  String name;
  String chatId;

  _ChatTilesState({
    this.chatPhotoUrl,
    this.name,
    this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => pushNewScreen(
        context,
        screen: ChatScreen(
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
                backgroundImage: null,
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
                      // Text(
                      //   chat.time,
                      //   style: TextStyle(
                      //     fontSize: 11,
                      //     fontWeight: FontWeight.w300,
                      //     color: Colors.white38,
                      //   ),
                      // ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    alignment: Alignment.topLeft,
                    // child: Text(
                    //   chat.text,
                    //   style: TextStyle(
                    //     fontSize: 13,
                    //     color: Colors.white60,
                    //   ),
                    //   overflow: TextOverflow.ellipsis,
                    //   maxLines: 2,
                    // ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
