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
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIsFollowing();
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
                            Icons.border_color,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          title: Text(
                            'Feedback',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () => {Navigator.of(context).pop()},
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
                        left: 12.0,
                        right: 12.0,
                        bottom: 3.0,
                      ),
                      child: Column(
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
                                    buildCountStats("Posts", postCount),
                                    buildCountStats("Followers", followersCount),
                                    buildCountStats("Following", followingCount),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(top: 15.0, left: 13),
                            child: Text(
                              user.userName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(top: 4.0, left: 13),
                            child: Text(
                              user.profileName,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(top: 2.0, left: 13),
                            child: Text(
                              user.bio,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [currentUserId != widget.userid ? buildFollowOrUnfollow() : Container()],
                          ),
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

  Column buildCountStats(String title, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).accentColor,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 5.0),
          child: Text(
            title,
            style: TextStyle(color: Theme.of(context).accentColor),
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
    return Container(
      padding: EdgeInsets.only(top: 7.0),
      child: TextButton(
        onPressed: function,
        child: Container(
          height: 27.0,
          width: 200.0,
          child: Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(
              color: Colors.blue,
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
}
