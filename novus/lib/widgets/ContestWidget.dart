import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/UploadPage.dart';
import 'package:novus/widgets/PostTileWidget.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class Contest extends StatefulWidget {
  final String contestName;
  final String contestId;
  final String contestDescription;
  final String hostUserId;
  final List participants;

  Contest({
    this.contestName,
    this.contestId,
    this.contestDescription,
    this.participants,
    this.hostUserId,
  });

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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_sharp,
            color: Theme.of(context).accentColor,
          ),
        ),
        title: Text(
          "Topic: " + widget.contestName,
          style: TextStyle(
            color: Colors.purple,
            fontSize: 25.0,
          ),
        ),
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
      ),
      endDrawer: widget.hostUserId == user.id
          ? new BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 0.5,
                sigmaY: 0.5,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.55,
                color: Colors.black,
                child: Drawer(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Container(
                          height: 100,
                          child: DrawerHeader(
                            padding: EdgeInsets.only(
                                bottom: 5.0, top: 10.0, left: 17.0),
                            child: Text(
                              'Contest Actions',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 25),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.settings,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          title: Text(
                            'Settings',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () => null,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.person_add,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          title: Text(
                            'Add participants',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () => addParticipants(),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.event_busy_outlined,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          title: Text(
                            'End contest',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () => null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: isLoading
          ? circularProgress()
          : Padding(
              padding:
                  const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 8.0),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Text(
                          "Topic: " + widget.contestName,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 30.0),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 5.0, bottom: 20.0),
                        child: Text(
                          widget.contestDescription,
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
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UploadPage(
                              contestId: widget.contestId,
                              contestUpload: true,
                              userUpload: user,
                            ),
                          ),
                        ),
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
                          "Leaderboard",
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
                        future: getLeaderboard(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return circularProgress();
                          return ListView(
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
    QuerySnapshot snapshot2 = await contestReference
        .doc(widget.contestId)
        .collection('partcipants')
        .doc(user.id)
        .collection('posts')
        .get();

    List<String> tempIDs = [];
    List<Post> tempPosts = [];
    snapshot2.docs.forEach((element) {
      tempIDs.add(element.id);
    });

    for (var i = 0; i < tempIDs.length; i++) {
      DocumentSnapshot snapshot = await postReference
          .doc(user.id)
          .collection('userPosts')
          .doc(tempIDs[i])
          .get();
      tempPosts.add(Post.fromDocument(snapshot));
    }
    //Stream<QuerySnapshot> sn = postReference.doc(user.id).collection('userPosts').where('postId', whereIn: tempIDs).snapshots();
    if (this.mounted)
      setState(() {
        isLoading = false;
        postCount = tempPosts.length;
        posts = tempPosts;
      });
  }

  tilesView() {
    if (posts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(45.0),
        child: Center(
          child: Text(
            'Post a picture',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w400, fontSize: 25),
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

  getLeaderboard() async {
    List<LeaderboardTile> leaderBoardTiles = [];
    for (var i = 0; i < widget.participants.length; i++) {
      DocumentSnapshot userFollowingIds =
          await userReference.doc(widget.participants[i]).get();
      leaderBoardTiles
          .add(LeaderboardTile.fromDocument(userFollowingIds, posts));
    }
    return leaderBoardTiles;
  }

  addParticipants() {
    return showDialog(
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
                    "Add someone you follow",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                FutureBuilder(
                  future: addParticipantsTiles(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return circularProgress();
                    return Container(
                      height: 500.0,
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: snapshot.data,
                      ),
                    );
                  },
                )
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
    );
  }

  addParticipantsTiles() async {
    List<UserTile> comments = [];
    QuerySnapshot usersfollowing =
        await userReference.doc(user.id).collection('following').get();
    usersfollowing.docs.forEach(
      (element) async {
        if (!widget.participants.contains(element)) {
          DocumentSnapshot usersfoll =
              await userReference.doc(element.id).get();
          comments.add(UserTile.fromDocument(usersfoll));
        }
      },
    );
    return comments;
  }
}

class LeaderboardTile extends StatelessWidget {
  final String contestName;
  final String contestId;
  final String contestDescription;
  final List<Post> postList;
  final String hostUserId;
  final String profileName;
  final String profileUrl;
  final List participants;

  LeaderboardTile({
    this.contestName,
    this.contestId,
    this.profileName,
    this.profileUrl,
    this.postList,
    this.contestDescription,
    this.participants,
    this.hostUserId,
  });

  factory LeaderboardTile.fromDocument(
      DocumentSnapshot doc, List<Post> postList) {
    return LeaderboardTile(
      profileName: doc.data()['profileName'],
      profileUrl: doc.data()['photoUrl'],
      contestId: doc.data()['contestId'],
      contestName: doc.data()['contestName'],
      postList: postList,
      contestDescription: doc.data()['description'],
      participants: doc.data()['participants'],
      hostUserId: doc.data()['hostUserId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Text(
              "#1",
              style: TextStyle(color: Colors.white),
            ),
          ),
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(profileUrl),
          ),
        ],
      ),
      subtitle: Text(
        "Score: " + getScore(postList),
        style: TextStyle(color: Colors.grey),
      ),
      title: Text(
        profileName,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  String getScore(List<Post> postList) {
    int score = 0;
    for (var i = 0; i < postList.length; i++) {
      score = score + postList[i].votes.length;
    }
    return score.toString();
  }
}

class UserTile extends StatelessWidget {
  final String profileName;
  final String profileUrl;
  final String username;

  UserTile({
    this.username,
    this.profileName,
    this.profileUrl,
  });

  factory UserTile.fromDocument(DocumentSnapshot doc) {
    return UserTile(
      profileName: doc.data()['profileName'],
      profileUrl: doc.data()['photoUrl'],
      username: doc.data()['userName'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(profileUrl),
      ),
      subtitle: Text(
        profileName,
        style: TextStyle(color: Colors.grey),
      ),
      title: Text(
        username,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
