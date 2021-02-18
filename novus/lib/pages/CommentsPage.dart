import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsPage extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String posturl;

  CommentsPage({
    this.postId,
    this.ownerId,
    this.posturl,
  });

  @override
  CommentsPageState createState() => CommentsPageState(
        postId: this.postId,
        ownerId: this.ownerId,
        posturl: this.posturl,
      );
}

class CommentsPageState extends State<CommentsPage> {
  final String postId;
  final String ownerId;
  final String posturl;
  TextEditingController textEditingController = TextEditingController();

  CommentsPageState({
    this.postId,
    this.ownerId,
    this.posturl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Comments"),
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder(
            stream: commentsReference.doc(postId).collection('comments').orderBy('timestamp', descending: false).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return circularProgress();
              List<Comment> comments = [];
              snapshot.data.docs.forEach((element) {
                comments.add(Comment.fromDocument(element));
              });
              return ListView(children: comments);
            },
          )),
          Divider(),
          ListTile(
              title: TextFormField(
                style: TextStyle(color: Colors.white),
                controller: textEditingController,
                decoration: InputDecoration(
                  hintText: "comment",
                ),
              ),
              trailing: TextButton(
                onPressed: () => addComment(),
                child: Text(
                  'Post',
                  style: TextStyle(color: Theme.of(context).accentColor, fontSize: 20.0),
                ),
              ))
        ],
      ),
    );
  }

  addComment() {
    DateTime timestamp = DateTime.now();
    commentsReference.doc(postId).collection('comments').add({
      'username': user.userName,
      'comment': textEditingController.text,
      'profileUrl': user.url,
      'userId': user.id,
      'timestamp': timestamp,
    });
    if (user.id != ownerId) {
      notificationsReference.doc(ownerId).collection("notificationItems").add({
        "type": "comment",
        "commentData": textEditingController.text,
        "username": user.userName,
        "userId": user.id,
        "photoUrl": user.url,
        "postId": postId,
        "postUrl": posturl,
        "timestamp": timestamp,
      });
    }
    textEditingController.clear();
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String comment;
  final String profileUrl;
  final String userId;
  final Timestamp timestamp;

  Comment({
    this.username,
    this.comment,
    this.profileUrl,
    this.userId,
    this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      comment: doc['comment'],
      profileUrl: doc['profileUrl'],
      timestamp: doc['timestamp'],
      userId: doc['userId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7.0),
          child: ListTile(
            title: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                comment,
                style: TextStyle(color: Colors.white),
              ),
            ),
            subtitle: Text(
              timeago.format(timestamp.toDate()),
              style: TextStyle(color: Colors.grey, fontSize: 11.0),
            ),
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(profileUrl),
            ),
          ),
        ),
      ],
    );
  }
}
