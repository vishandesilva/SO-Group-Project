import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'ProfilePage.dart';

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
  bool isEnabled = false;

  CommentsPageState({
    this.postId,
    this.ownerId,
    this.posturl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Comments"),
      body: GestureDetector(
        onTap: () => WidgetsBinding.instance.focusManager.primaryFocus?.unfocus(),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: commentsReference.doc(postId).collection('comments').orderBy('timestamp', descending: false).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) return circularProgress();
                  List<Comment> comments = [];
                  snapshot.data.docs.forEach(
                    (element) {
                      comments.add(Comment.fromDocument(element));
                    },
                  );
                  return ListView(children: comments);
                },
              ),
            ),
            Divider(
              height: 0.01,
            ),
            ListTile(
              title: TextFormField(
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  value.length > 0 ? setState(() => isEnabled = true) : setState(() => isEnabled = false);
                },
                controller: textEditingController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Add a comment",
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              trailing: TextButton(
                onPressed: () => isEnabled ? addComment() : null,
                child: Text(
                  'Post',
                  style: TextStyle(
                    color: isEnabled ? Theme.of(context).accentColor : Theme.of(context).accentColor.withAlpha(150),
                    fontSize: 20.0,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  addComment() {
    DateTime timestamp = DateTime.now();
    var df = commentsReference.doc(postId).collection('comments').doc();
    commentsReference.doc(postId).collection('comments').doc(df.id).set({
      'username': user.userName,
      'comment': textEditingController.text,
      'commentId': df.id,
      'postId': postId,
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
  final String postId;
  final String commentId;
  final Timestamp timestamp;

  Comment({
    this.username,
    this.comment,
    this.commentId,
    this.profileUrl,
    this.userId,
    this.postId,
    this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc.data()['username'],
      comment: doc.data()['comment'],
      commentId: doc.data()['commentId'],
      postId: doc.data()['postId'],
      profileUrl: doc.data()['profileUrl'],
      timestamp: doc.data()['timestamp'],
      userId: doc.data()['userId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 1.0),
          child: GestureDetector(
            onLongPress: () => userId == user.id
                ? showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        contentPadding: EdgeInsets.all(0.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        backgroundColor: Colors.grey[900],
                        title: Center(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  "Delete this comment?",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 15.0, left: 20.0, right: 20.0),
                                child: Text(
                                  "This action will remove the comment from this post and cannot be undone.",
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 15.0),
                                ),
                              ),
                            ],
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
                                  "Delete",
                                  style: TextStyle(
                                    color: Theme.of(context).accentColor,
                                    fontSize: 17.0,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () {
                              deleteComment();
                              Navigator.pop(context);
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
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      );
                    },
                  )
                : null,
            child: ListTile(
              title: RichText(
                overflow: TextOverflow.visible,
                text: TextSpan(
                  style: TextStyle(fontSize: 15.0, color: Colors.white),
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()..onTap = () => showProfile(context),
                    ),
                    TextSpan(
                      text: ' $comment',
                    ),
                  ],
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
        ),
      ],
    );
  }

  showProfile(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          userid: userId,
        ),
      ),
    );
  }

  deleteComment() {
    commentsReference.doc(postId).collection('comments').doc(commentId).delete();
  }
}
