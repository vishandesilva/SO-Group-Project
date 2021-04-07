import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/EditProfilePage.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/PostTileWidget.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';

class ProfilePage extends StatefulWidget {
  final String userid;
  ProfilePage({this.userid});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String currentUserId = user?.id;
  bool isLoading = false;
  bool isFollowing = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts;

  @override
  void initState() {
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIsFollowing();
    super.initState();
  }

  checkIsFollowing() async {
    DocumentSnapshot snapshot = await userReference.doc(currentUserId).collection('following').doc(widget.userid).get();
    if (this.mounted)
      setState(() {
        isFollowing = snapshot.exists;
      });
  }

  void getFollowers() async {
    QuerySnapshot snapshot = await userReference.doc(widget.userid).collection('followers').get();
    if (this.mounted)
      setState(() {
        followersCount = snapshot.size;
      });
  }

  void getFollowing() async {
    QuerySnapshot snapshot = await userReference.doc(widget.userid).collection('following').get();
    if (this.mounted)
      setState(() {
        followingCount = snapshot.size;
      });
  }

  getProfilePosts() async {
    if (this.mounted) setState(() => isLoading = true);
    QuerySnapshot snapshot =
        await postReference.doc(widget.userid).collection('userPosts').orderBy('timestamp', descending: true).get();
    if (this.mounted)
      setState(() {
        isLoading = false;
        postCount = snapshot.docs.length;
        posts = snapshot.docs.map((e) => Post.fromDocument(e)).toList();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: 'Profile'),
      endDrawer: widget.userid == currentUserId
          ? BackdropFilter(
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
                            padding: EdgeInsets.only(bottom: 5.0, top: 10.0, left: 17.0),
                            child: Text(
                              user.userName,
                              style: TextStyle(color: Colors.white, fontSize: 25),
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(userId: widget.userid),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.exit_to_app,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          title: Text(
                            'Logout',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () => {googleSignIn.signOut()},
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
          : ListView(
              children: [
                StreamBuilder(
                  stream: userReference.doc(widget.userid).snapshots(),
                  builder: (context, currentSnapshot) {
                    if (!currentSnapshot.hasData) return circularProgress();
                    User user = User.fromDocument(currentSnapshot.data);
                    return Padding(
                      padding: EdgeInsets.only(
                        top: 12.0,
                        left: 10.0,
                        right: 10.0,
                        bottom: 3.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: CachedNetworkImageProvider(user.url),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    buildCountStats("Posts", postCount, context),
                                    buildCountStats("Followers", followersCount, context),
                                    buildCountStats("Following", followingCount, context),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(top: 15.0, left: 10),
                            child: Text(
                              user.userName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(top: 4.0, left: 10),
                            child: Text(
                              user.profileName,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(top: 2.0, left: 10),
                            child: Text(
                              user.bio,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              currentUserId != widget.userid
                                  ? buildFollowOrUnfollow()
                                  : SizedBox(
                                      width: 0,
                                    ),
                              buildAchievements()
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.only(top: 4.0, left: 10),
                                child: Text(
                                  user.points < 10
                                      ? "Level: 1"
                                      : user.points < 20
                                          ? "Level: 2"
                                          : user.points < 30
                                              ? "Level: 3"
                                              : user.points < 40
                                                  ? "Level: 4"
                                                  : "Level: 5",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18.0),
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.only(top: 4.0, left: 10),
                                child: Text(
                                  "Points: " + user.points.toString(),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18.0),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 2.0),
                  child: Divider(
                    height: 0.0,
                  ),
                ),
                tilesView(),
                //TODO potentially add toggle between listview and tileview
                //Column(children: posts)
              ],
            ),
    );
  }

  Column buildCountStats(String title, int count, BuildContext context) {
    return title == "Followers" || title == "Following"
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count.toString(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              GestureDetector(
                onTap: () => fTiles(title, context),
                child: Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5.0),
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          );
  }

  buildFollowOrUnfollow() {
    String title;
    Function function;
    if (isFollowing) {
      title = "Unfollow";
      function = handleUnfollow;
    } else {
      title = "Follow";
      function = handleFollow;
    }
    return Expanded(
      child: TextButton(
        onPressed: function,
        child: Container(
          height: 27.0,
          child: Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            border: Border.all(
              color: Theme.of(context).accentColor,
            ),
            borderRadius: BorderRadius.circular(3.0),
          ),
        ),
      ),
    );
  }

  tilesView() {
    if (posts.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 200),
        child: Center(
          child: Text(
            'Upload Photos',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 40,
            ),
          ),
        ),
      );
    }
    List<GridTile> gridTiles = [];
    posts.forEach(
      (element) {
        gridTiles.add(
          GridTile(
            child: PostTile(
              post: element,
              isProfilePage: true,
            ),
          ),
        );
      },
    );
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

  handleUnfollow() {
    setState(() {
      isFollowing = false;
    });
    userReference.doc(widget.userid).collection('followers').doc(currentUserId).get().then(
      (value) {
        if (value.exists) value.reference.delete();
      },
    );
    userReference.doc(currentUserId).collection('following').doc(widget.userid).get().then(
      (value) {
        if (value.exists) value.reference.delete();
      },
    );
    notificationsReference.doc(widget.userid).collection('notificationItems').doc(currentUserId).get().then(
      (value) {
        if (value.exists) value.reference.delete();
      },
    );
  }

  handleFollow() {
    setState(() {
      isFollowing = true;
    });
    DateTime timestamp = DateTime.now();
    userReference.doc(widget.userid).collection('followers').doc(currentUserId).set({});
    userReference.doc(currentUserId).collection('following').doc(widget.userid).set({});
    notificationsReference.doc(widget.userid).collection('notificationItems').doc(currentUserId).set({
      "type": "follow",
      "ownerId": widget.userid,
      "username": user.userName,
      "userId": currentUserId,
      "photoUrl": user.url,
      "timestamp": timestamp,
    });
  }

  fTiles(String title, BuildContext context) {
    showDialog(
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
                    title,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  height: 400,
                  width: double.maxFinite,
                  child: FutureBuilder(
                    future: addParticipantsTiles(title.toLowerCase()),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return circularProgress();

                      return Container(
                        child: ListView(
                          shrinkWrap: true,
                          children: snapshot.data,
                        ),
                      );
                    },
                  ),
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
                    "Back",
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

  addParticipantsTiles(String title) async {
    List<String> tempIDs = [];
    List<UserResult> comments = [];
    QuerySnapshot usersfollowing = await userReference.doc(widget.userid).collection(title).get();

    usersfollowing.docs.forEach((element) {
      tempIDs.add(element.id);
    });

    for (var i = 0; i < tempIDs.length; i++) {
      DocumentSnapshot usersfoll = await userReference.doc(tempIDs[i]).get();
      comments.add(UserResult(User.fromDocument(usersfoll)));
    }
    return comments;
  }

  buildAchievements() {
    return Expanded(
      child: TextButton(
        onPressed: () => userAchievements(),
        child: Container(
          height: 27.0,
          child: Text(
            "Achievements",
            style: TextStyle(color: Colors.white),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            border: Border.all(
              color: Theme.of(context).accentColor,
            ),
            borderRadius: BorderRadius.circular(3.0),
          ),
        ),
      ),
    );
  }

  userAchievements() {
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
                    'Achievements',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  height: 400,
                  width: double.maxFinite,
                  child: StreamBuilder(
                    stream: userReference.doc(user.id).collection("achievements").get().asStream(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) return circularProgress();
                      List<AchievementTiles> tiles = [];
                      snapshot.data.docs.forEach((element) {
                        tiles.add(AchievementTiles.fromDocument(element));
                      });
                      return Container(
                        child: ListView(
                          shrinkWrap: true,
                          children: tiles,
                        ),
                      );
                    },
                  ),
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
                    "Back",
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
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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

class AchievementTiles extends StatelessWidget {
  final int score;
  final int rank;
  final String contestId;
  final String contestName;
  final String hostName;

  AchievementTiles({
    this.score,
    this.rank,
    this.contestId,
    this.contestName,
    this.hostName,
  });

  factory AchievementTiles.fromDocument(DocumentSnapshot doc) {
    return AchievementTiles(
      score: doc.data()['score'],
      rank: doc.data()['rank'],
      contestName: doc.data()['contestName'],
      contestId: doc.data()['contestId'],
      hostName: doc.data()['hostName'],
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
              "#" + rank.toString(),
              style: TextStyle(
                color: rank == 1
                    ? Colors.yellow
                    : rank == 2
                        ? Colors.grey[300]
                        : rank == 3
                            ? Colors.brown[700]
                            : Colors.white,
                fontSize: 25.0,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        hostName,
        style: TextStyle(color: Colors.grey),
      ),
      trailing: Text(
        "Score: " + score.toString(),
        style: TextStyle(color: Colors.white),
      ),
      title: Text(
        contestName,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
