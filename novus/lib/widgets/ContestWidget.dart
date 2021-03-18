import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/PostScreenPage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/PostTileWidget.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class Contest extends StatefulWidget {
  @override
  _ContestState createState() => _ContestState();
}

class _ContestState extends State<Contest> {
  int postCount;
  bool isLoading = false;
  List<Post> posts;

  void initState() {
    super.initState();
    getContestPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Contest"),
      body: isLoading
          ? circularProgress()
          : Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 8.0),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Text(
                          "Topic: Beaches",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30.0),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 5.0, bottom: 20.0),
                        child: Text(
                          "Its summer time, get yourself outside and take pictures of the best beach spots that you can find. Good luck and have fun!",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Photos Posted: " + postCount.toString() + "/3",
                        style: TextStyle(color: Colors.white, fontSize: 20.0),
                      ),
                      GestureDetector(
                        child: Text(
                          "Post",
                          style: TextStyle(color: Colors.blue, fontSize: 20.0),
                        ),
                      )
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 0.5,
                        color: Colors.purple,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          isLoading ? circularProgress() : tilesView(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: [
                        Text(
                          "Contest Leaderboard",
                          style: TextStyle(color: Colors.white, fontSize: 25.0),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 0.5,
                          color: Colors.purple,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: FutureBuilder(
                        future: getUserNotifications(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return circularProgress();
                          return ListView(
                            shrinkWrap: true,
                            children: snapshot.data,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  getContestPosts() async {
    if (this.mounted) {
      setState(() => isLoading = true);
    }

    QuerySnapshot snapshot =
        await postReference.doc(user.id).collection('userPosts').orderBy('timestamp', descending: true).get();

    if (this.mounted)
      setState(() {
        isLoading = false;
        postCount = snapshot.docs.length;
        posts = snapshot.docs.map((e) => Post.fromDocument(e)).toList();
      });
  }

  tilesView() {
    if (posts.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 200),
        child: Center(
          child: Text(
            'Upload Photos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 40),
          ),
        ),
      );
    }
    List<GridTile> gridTiles = [];
    posts.forEach((element) {
      gridTiles.add(
        GridTile(
          child: PostTile(
            post: element,
          ),
        ),
      );
    });
    return GridView.count(
      children: gridTiles,
      crossAxisSpacing: 2.0,
      crossAxisCount: 3,
      childAspectRatio: 1.0,
      mainAxisSpacing: 2.0,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
    );
  }

  //TODO add uploading photos logic for contests
  uploadContestPhoto() {}
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
      userId: doc['userId'],
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
