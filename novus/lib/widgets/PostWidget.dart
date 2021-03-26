import 'dart:async';
import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/CommentsPage.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/widgets/ProgressWidget.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String caption;
  final String posturl;
  final DateTime timestamp;
  final Map votes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.caption,
    this.posturl,
    this.votes,
    this.timestamp,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc.data()['postId'],
      ownerId: doc.data()['ownerId'],
      username: doc.data()['username'],
      location: doc.data()['location'],
      caption: doc.data()['caption'],
      posturl: doc.data()['postUrl'],
      votes: doc.data()['votes'],
      timestamp: doc.data()['timestamp'].toDate(),
    );
  }

  int getLikeCount(Map votes) {
    if (votes == null) return 0;
    int votesCount = 0;
    votes.values.forEach((value) {
      if (value == true) votesCount += 1;
    });
    return votesCount;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        caption: this.caption,
        voteCount: this.getLikeCount(votes),
        votes: this.votes,
        location: this.location,
        posturl: this.posturl,
        username: this.username,
        timestamp: this.timestamp,
      );
}

class _PostState extends State<Post> {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String caption;
  final String posturl;
  final DateTime timestamp;
  int voteCount;
  Map votes;
  bool isVotedEnabled;
  bool showVote = false;
  final String userId = user.id;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.caption,
    this.posturl,
    this.voteCount,
    this.votes,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    isVotedEnabled = votes[userId] == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // building post header
        StreamBuilder(
          stream: userReference.doc(ownerId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return circularProgress();
            User user = User.fromDocument(snapshot.data);
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.url),
              ),
              title: GestureDetector(
                onTap: () => showProfile(context),
                child: Text(
                  user.userName,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              subtitle: Text(
                location,
                style: TextStyle(color: Colors.white),
              ),
              trailing: userId == ownerId
                  ? IconButton(
                      icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                      onPressed: () => showDialog(
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
                                      "Delete this post?",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 15.0, left: 20.0, right: 20.0),
                                    child: Text(
                                      "This action will remove this post from your profile and cannot be undone.",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.normal,
                                        fontSize: 15.0,
                                      ),
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
                                  Navigator.pop(context);
                                  deletePost();
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
                      ),
                    )
                  : null,
            );
          },
        ),
        // build the image in a post
        GestureDetector(
          onDoubleTap: () => handleVotes(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CachedNetworkImage(
                imageUrl: posturl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Padding(
                  padding: EdgeInsets.all(10.0),
                  child: circularProgress(),
                ),
                errorWidget: (context, url, error) => Icon(Icons.error_outline),
              ),
              showVote
                  ? Animator(
                      duration: Duration(milliseconds: 300),
                      tween: Tween(begin: 0.8, end: 1.4),
                      curve: Curves.bounceOut,
                      cycles: 0,
                      builder: (context, anim, child) => Transform.scale(
                        scale: anim.value,
                        child: Icon(
                          Icons.arrow_upward,
                          size: 80,
                          color: Colors.green,
                        ),
                      ),
                    )
                  : Text("")
            ],
          ),
        ),
        // build the footer in a post
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 40.0, left: 20.0),
                ),
                GestureDetector(
                  onTap: () => handleVotes(),
                  child: Icon(
                    Icons.arrow_upward_outlined,
                    size: 31.0,
                    color: isVotedEnabled ? Colors.green : Colors.white,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 20.0),
                ),
                GestureDetector(
                  onTap: () => openCommentsScreen(context, postId, ownerId, posturl),
                  child: Icon(
                    Icons.comment,
                    size: 25.0,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 20.0),
                  child: Text(
                    '$voteCount votes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 20.0),
                  child: Text(
                    '$username ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    caption,
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ],
        ),
        Padding(padding: EdgeInsets.only(bottom: 15.0))
      ],
    );
  }

  handleVotes() {
    bool isVoted = votes[userId] == true;
    if (isVoted) {
      postReference.doc(ownerId).collection('userPosts').doc(postId).update({'votes.$userId': false});
      removeVoteNotification();
      setState(() {
        voteCount -= 1;
        isVotedEnabled = false;
        votes[userId] = false;
      });
    } else if (!isVoted) {
      postReference.doc(ownerId).collection('userPosts').doc(postId).update({'votes.$userId': true});
      addVoteNotification();
      setState(
        () {
          voteCount += 1;
          isVotedEnabled = true;
          votes[userId] = true;
          showVote = true;
          Timer(
            Duration(milliseconds: 400),
            () {
              setState(
                () {
                  showVote = false;
                },
              );
            },
          );
        },
      );
    }
  }

  void openCommentsScreen(BuildContext context, String postId, String ownerId, String posturl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommentsPage(
          postId: postId,
          posturl: posturl,
          ownerId: ownerId,
        ),
      ),
    );
  }

  void addVoteNotification() {
    if (user.id != ownerId) {
      DateTime timestamp = new DateTime.now();
      notificationsReference.doc(ownerId).collection("notificationItems").doc(postId).set(
        {
          "type": "vote",
          "username": user.userName,
          "userId": user.id,
          "photoUrl": user.url,
          "postId": postId,
          "postUrl": posturl,
          "timestamp": timestamp,
        },
      );
    }
  }

  void removeVoteNotification() {
    if (user.id != ownerId) {
      notificationsReference
          .doc(ownerId)
          .collection("notificationItems")
          .doc(postId)
          .get()
          .then((value) => value.exists ? value.reference.delete() : null);
    }
  }

  showProfile(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          userid: ownerId,
        ),
      ),
    );
  }

  deletePost() async {
    postReference
        .doc(ownerId)
        .collection('userPosts')
        .doc(postId)
        .get()
        .then((value) => value.exists ? value.reference.delete() : null);

    storageReference.child("posts").child("post_$postId.jpg").delete();

    QuerySnapshot deletingNotifications =
        await notificationsReference.doc(ownerId).collection("notificationItems").where('postId', isEqualTo: postId).get();
    deletingNotifications.docs.forEach((element) {
      if (element.exists) {
        element.reference.delete();
      }
    });

    QuerySnapshot deletingComments = await commentsReference.doc(postId).collection('comments').get();
    deletingComments.docs.forEach((element) {
      if (element.exists) {
        element.reference.delete();
      }
    });

    setState(() {});
  }
}
