import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/PostScreenPage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: 'Activity'),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Text(
              "Notifications",
              style: TextStyle(color: Theme.of(context).accentColor, fontSize: 17),
            ),
          ),
          FutureBuilder(
            future: getUserNotifications(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return circularProgress();
              return ListView(
                physics: ClampingScrollPhysics(),
                shrinkWrap: true,
                children: snapshot.data,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 35.0),
            child: Text(
              "Trending Accounts",
              style: TextStyle(color: Theme.of(context).accentColor, fontSize: 17),
            ),
          ),
          StreamBuilder(
            stream: userReference.orderBy('points', descending: true).limit(5).get().asStream(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return circularProgress();
              List<UserResult> trending = [];
              snapshot.data.docs.forEach((element) {
                trending.add(UserResult(User.fromDocument(element), true));
              });
              return ListView(
                physics: ClampingScrollPhysics(),
                shrinkWrap: true,
                children: trending,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 35.0),
            child: Text(
              "Suggested Profiles",
              style: TextStyle(color: Theme.of(context).accentColor, fontSize: 17),
            ),
          ),
          StreamBuilder(
            stream: userReference.doc(user.id).collection('following').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              return StreamBuilder(
                stream: userReference.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot2) {
                  if (!snapshot.hasData || !snapshot2.hasData) return circularProgress();
                  List<String> userFollowingIds = [user.id];
                  snapshot.data.docs.forEach(
                    (element) {
                      userFollowingIds.add(element.id);
                    },
                  );

                  List<UserResult> trending = [];
                  snapshot2.data.docs.forEach(
                    (element) {
                      if (!userFollowingIds.contains(element.id)) {
                        trending.add(UserResult(User.fromDocument(element), false));
                      }
                    },
                  );

                  return ListView(
                    physics: ClampingScrollPhysics(),
                    shrinkWrap: true,
                    children: trending,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

getUserNotifications() async {
  QuerySnapshot snapshot = await notificationsReference
      .doc(user.id)
      .collection('notificationItems')
      .orderBy('timestamp', descending: true)
      .limit(25)
      .get();
  List<NotificationsItem> notificationItems = [];
  snapshot.docs.forEach(
    (element) {
      notificationItems.add(NotificationsItem.fromDocument(element));
    },
  );
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

class UserResult extends StatelessWidget {
  final User user;
  final bool isTrend;

  UserResult(this.user, this.isTrend);
  @override
  Widget build(BuildContext context) {
    return isTrend
        ? GestureDetector(
            onTap: () => showProfile(context),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.url),
              ),
              title: Text(
                user.profileName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                user.userName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12.0,
                ),
              ),
              trailing: Text(
                user.points.toString() + " points",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15.0,
                ),
              ),
            ),
          )
        : GestureDetector(
            onTap: () => showProfile(context),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.url),
              ),
              title: Text(
                user.profileName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                user.userName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12.0,
                ),
              ),
            ),
          );
  }

  showProfile(context) {
    pushNewScreen(
      context,
      screen: ProfilePage(
        userid: user.id,
      ),
      withNavBar: true, // OPTIONAL VALUE. True by default.
      pageTransitionAnimation: PageTransitionAnimation.fade,
    );
  }
}
