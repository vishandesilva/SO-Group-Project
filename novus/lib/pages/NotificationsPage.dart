import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/PostScreenPage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: 'Notifications'),
      body: Container(
        child: FutureBuilder(
          future: getUserNotifications(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return circularProgress();
            return ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }
}

getUserNotifications() async {
  QuerySnapshot snapshot =
      await notificationsReference.doc(user.id).collection('notificationItems').orderBy('timestamp', descending: true).get();
  List<NotificationsItem> notificationItems = [];
  snapshot.docs.forEach((element) {
    notificationItems.add(NotificationsItem.fromDocument(element));
  });
  return notificationItems;
}

Widget mediaType;
String notificationText;

class NotificationsItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type;
  final String photoUrl;
  final String postId;
  final String postUrl;
  final String commentData;
  final Timestamp timestamp;

  NotificationsItem({
    this.username,
    this.userId,
    this.type,
    this.photoUrl,
    this.postId,
    this.postUrl,
    this.commentData,
    this.timestamp,
  });

  factory NotificationsItem.fromDocument(DocumentSnapshot doc) {
    return NotificationsItem(
      username: doc.data()['username'],
      userId: doc.data()['userId'],
      type: doc.data()['type'],
      postId: doc.data()['postId'],
      postUrl: doc.data()['postUrl'],
      photoUrl: doc.data()['photoUrl'],
      commentData: doc.data()['commentData'],
      timestamp: doc.data()['timestamp'],
    );
  }

  setupMediaPreview(context) {
    if (type == 'vote' || type == 'comment') {
      mediaType = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(postUrl),
                ),
              ),
            ),
          ),
        ),
      );
    } else
      mediaType = Text('');

    if (type == 'vote')
      notificationText = "voted on your post";
    else if (type == 'follow')
      notificationText = "is following you";
    else if (type == 'comment')
      notificationText = "replied $commentData";
    else
      notificationText = "err";
  }

  @override
  Widget build(BuildContext context) {
    setupMediaPreview(context);
    return Padding(
      padding: EdgeInsets.all(1.0),
      child: ListTile(
        title: RichText(
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: TextStyle(fontSize: 14.0, color: Colors.white),
            children: [
              TextSpan(
                text: username,
                style: TextStyle(fontWeight: FontWeight.bold),
                recognizer: TapGestureRecognizer()..onTap = () => showProfile(context),
              ),
              TextSpan(
                text: ' $notificationText',
              ),
            ],
          ),
        ),
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(photoUrl),
        ),
        subtitle: Text(
          timeago.format(timestamp.toDate()),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey, fontSize: 11.0),
        ),
        trailing: mediaType,
      ),
    );
  }

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreenPage(
          userId: user.id,
          postId: postId,
        ),
      ),
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
}
