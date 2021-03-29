import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/current_remaining_time.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/UploadPage.dart';
import 'package:novus/pages/contestTImeline.dart';
import 'package:novus/widgets/PostTileWidget.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';

List<UserTile> addUsers;

// ignore: must_be_immutable
class Contest extends StatefulWidget {
  final String contestName;
  final String contestId;
  final String contestDescription;
  final String hostUserId;
  final int endDate;
  bool contestEnd;
  final List participants;

  Contest({
    this.contestName,
    this.contestId,
    this.contestEnd,
    this.contestDescription,
    this.participants,
    this.hostUserId,
    this.endDate,
  });

  @override
  _ContestState createState() => _ContestState();
}

class _ContestState extends State<Contest> {
  final TextEditingController contestNameController = TextEditingController();
  final TextEditingController contestDesriptionController = TextEditingController();
  int postCount;
  bool isLoading = false;
  List<Post> posts;
  bool lockPostButton = false;
  LeaderboardTile userPlacement;

  void initState() {
    super.initState();
    getContestPosts();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(
                text: "Details",
              ),
              Tab(
                text: "Leaderboard",
              ),
            ],
          ),
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
              color: Theme.of(context).primaryColor,
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
                              padding: EdgeInsets.only(bottom: 5.0, top: 10.0, left: 17.0),
                              child: Text(
                                'Contest Actions',
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
                            onTap: () => contestSettingsForm(),
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
            : TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Description: " + widget.contestDescription,
                            style: TextStyle(color: Colors.white, fontSize: 17.0),
                          ),
                        ),
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: CountdownTimer(
                              textStyle: TextStyle(color: Colors.white),
                              endTime: widget.endDate,
                              widgetBuilder: (context, CurrentRemainingTime time) {
                                if (time == null) {
                                  contestReference.doc(widget.contestId).update({'contestEnd': true});
                                  userReference.doc(user.id).update({'points': FieldValue.increment(getScore(posts))});
                                  lockPostButton = true;
                                  return TextButton(
                                    child: Text("View results"),
                                    onPressed: () {
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
                                                      "Achievements",
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                  Center(
                                                    child: Container(
                                                      width: double.maxFinite,
                                                      height: 100,
                                                      child: FutureBuilder(
                                                        future: getResult(),
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
                                                      "Add to profile",
                                                      style: TextStyle(
                                                        color: Theme.of(context).accentColor,
                                                        fontSize: 17.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  addAchievementProfile();
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
                                                      "Back",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 17.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                  child: Text(
                                    'Time left: Days: ${time.days == null ? '0' : time.days}, Hours: ${time.hours == null ? '0' : time.hours}, Min: ${time.min == null ? '0' : time.min}',
                                    style: TextStyle(color: Colors.white, fontSize: 17.0),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Photos Posted: " + postCount.toString() + "/3",
                              style: TextStyle(color: Colors.white, fontSize: 20.0),
                            ),
                            GestureDetector(
                              onTap: () => !lockPostButton
                                  ? Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UploadPage(
                                          contestId: widget.contestId,
                                          contestUpload: true,
                                          userUpload: user,
                                        ),
                                      ),
                                    )
                                  : null,
                              child: Text(
                                "Post",
                                style: TextStyle(
                                  color: lockPostButton ? Colors.blue.withAlpha(150) : Colors.blue,
                                  fontSize: 20.0,
                                ),
                              ),
                            )
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                              color: Theme.of(context).primaryColor,
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
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                              color: Theme.of(context).primaryColor,
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
                ],
              ),
      ),
    );
  }

  contestSettingsForm() {
    return showDialog(
      context: context,
      builder: (context) {
        bool _contestName = true;
        contestDesriptionController.text = widget.contestDescription;
        contestNameController.text = widget.contestName;
        return StatefulBuilder(
          builder: (context, setState) {
            return SimpleDialog(
              contentPadding: EdgeInsets.all(0.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              backgroundColor: Colors.grey[900],
              title: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Container(
                  width: double.maxFinite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Contest Details",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: contestNameController,
                          decoration: InputDecoration(
                            labelText: "Title",
                            labelStyle: TextStyle(color: Colors.white),
                            hintText: "Provide a name",
                            hintStyle: TextStyle(color: Colors.white38),
                            errorText: !_contestName ? "name required" : null,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          cursorColor: Colors.white,
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: contestDesriptionController,
                          decoration: InputDecoration(
                            labelText: "Description",
                            labelStyle: TextStyle(color: Colors.white),
                            hintText: "About your contest",
                            hintStyle: TextStyle(color: Colors.white38),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          cursorColor: Colors.white,
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        "Accept changes",
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 17.0,
                        ),
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(
                      () {
                        if (contestNameController.text.isEmpty) {
                          _contestName = false;
                        } else {
                          _contestName = true;
                        }
                      },
                    );

                    if (_contestName) {
                      contestReference.doc(widget.contestId).update({
                        'contestName': contestNameController.text,
                        'description': contestDesriptionController.text,
                      });
                      contestNameController.clear();
                      contestDesriptionController.clear();
                      Navigator.pop(context);
                    }
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
                  onPressed: () {
                    contestNameController.clear();
                    contestDesriptionController.clear();
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  getContestPosts() async {
    if (this.mounted) {
      setState(() => isLoading = true);
    }

    QuerySnapshot snapshot2 =
        await contestReference.doc(widget.contestId).collection('partcipants').doc(user.id).collection('posts').get();

    List<String> tempIDs = [];
    List<Post> tempPosts = [];
    snapshot2.docs.forEach(
      (element) {
        tempIDs.add(element.id);
      },
    );

    for (var i = 0; i < tempIDs.length; i++) {
      DocumentSnapshot snapshot = await postReference.doc(user.id).collection('userPosts').doc(tempIDs[i]).get();
      tempPosts.add(Post.fromDocument(snapshot));
    }

    if (this.mounted)
      setState(
        () {
          isLoading = false;
          postCount = tempPosts.length;
          if (postCount == 3) lockPostButton = true;
          posts = tempPosts;
        },
      );
  }

  tilesView() {
    if (posts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(45.0),
        child: Center(
          child: Text(
            'Post a picture',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 25),
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

  int getScore(List<Post> postList) {
    int score = 0;
    for (var i = 0; i < postList.length; i++) {
      score = score + postList[i].votes.length;
    }
    return score;
  }

  getLeaderboard() async {
    List<LeaderboardTile> leaderBoardTiles = [];
    for (var i = 0; i < widget.participants.length; i++) {
      DocumentSnapshot userFollowingIds = await userReference.doc(widget.participants[i]).get();

      QuerySnapshot snapshot2 = await contestReference
          .doc(widget.contestId)
          .collection('partcipants')
          .doc(widget.participants[i])
          .collection('posts')
          .get();

      List<String> tempIDs = [];
      List<Post> tempPosts = [];
      if (snapshot2.docs.isNotEmpty) {
        snapshot2.docs.forEach((element) {
          tempIDs.add(element.id);
        });

        for (var i = 0; i < tempIDs.length; i++) {
          DocumentSnapshot snapshot = await postReference.doc(user.id).collection('userPosts').doc(tempIDs[i]).get();
          tempPosts.add(Post.fromDocument(snapshot));
        }
      }

      leaderBoardTiles.add(LeaderboardTile.fromDocument(userFollowingIds, getScore(tempPosts), widget.contestId));
    }

    leaderBoardTiles.sort((a, b) => b.score.compareTo(a.score));

    for (var i = 0; i < leaderBoardTiles.length; i++) {
      leaderBoardTiles[i].rank = i + 1;
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
                Container(
                  height: 400,
                  width: double.maxFinite,
                  child: FutureBuilder(
                    future: userTiles(),
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
                    "Add",
                    style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontSize: 17.0,
                    ),
                  ),
                ),
              ),
              onPressed: () {
                addUsers.forEach((element) {
                  if (element.selected) {
                    contestReference.doc(widget.contestId).update({
                      'participants': FieldValue.arrayUnion([element.userId])
                    });
                  }
                });
                addUsers.clear();
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

  userTiles() async {
    List<String> tempIDs = [];
    List<UserTile> comments = [];
    QuerySnapshot usersfollowing = await userReference.doc(user.id).collection('following').get();

    usersfollowing.docs.forEach((element) {
      tempIDs.add(element.id);
    });

    for (var i = 0; i < tempIDs.length; i++) {
      if (!widget.participants.contains(tempIDs[i])) {
        DocumentSnapshot usersfoll = await userReference.doc(tempIDs[i]).get();
        comments.add(UserTile.fromDocument(usersfoll));
      }
    }
    addUsers = comments;
    return comments;
  }

  getResult() async {
    List<LeaderboardTile> leaderboard = await getLeaderboard();
    LeaderboardTile temp = leaderboard[leaderboard.indexWhere((element) => element.userid == user.id)];
    setState(() {
      userPlacement = temp;
    });
    return [temp];
  }

  int getTime() {
    var today = DateTime.now();
    var fiftyDaysFromNow = today.add(const Duration(days: 4));
    int dateTimeCreatedAt = fiftyDaysFromNow.millisecondsSinceEpoch;
    return dateTimeCreatedAt;
  }

  void addAchievementProfile() async {
    DocumentSnapshot tempSnapshot = await userReference.doc(user.id).collection('achievements').doc(widget.contestId).get();
    if (!tempSnapshot.exists) {
      DocumentSnapshot hostUserSnapshot = await userReference.doc(widget.hostUserId).get();
      User hostUser = User.fromDocument(hostUserSnapshot);
      userReference.doc(user.id).collection('achievements').doc(widget.contestId).set({
        'score': userPlacement.score,
        'rank': userPlacement.rank,
        'contestId': widget.contestId,
        'contestName': widget.contestName,
        'hostName': hostUser.userName,
      });
    }
  }
}

// ignore: must_be_immutable
class LeaderboardTile extends StatelessWidget {
  final String contestName;
  final String userid;
  final String contestId;
  final String contestDescription;
  final List<Post> postList;
  final String hostUserId;
  final String profileName;
  final String profileUrl;
  final List participants;
  int rank;
  final int score;

  LeaderboardTile({
    this.userid,
    this.contestName,
    this.contestId,
    this.profileName,
    this.profileUrl,
    this.postList,
    this.contestDescription,
    this.participants,
    this.hostUserId,
    this.rank,
    this.score,
  });

  factory LeaderboardTile.fromDocument(DocumentSnapshot doc, int score, String contestId) {
    return LeaderboardTile(
      profileName: doc.data()['profileName'],
      profileUrl: doc.data()['photoUrl'],
      contestId: contestId,
      contestName: doc.data()['contestName'],
      userid: doc.data()['id'],
      score: score,
      contestDescription: doc.data()['description'],
      participants: doc.data()['participants'],
      hostUserId: doc.data()['hostUserId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ContestTimeline(
            userId: userid,
            contestId: contestId,
            profileName: profileName,
          ),
        ),
      ),
      child: ListTile(
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
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(profileUrl),
            ),
          ],
        ),
        subtitle: Text(
          "Score: " + score.toString(),
          style: TextStyle(color: Colors.grey),
        ),
        title: Text(
          profileName,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class UserTile extends StatefulWidget {
  final String profileName;
  final String profileUrl;
  final String userId;
  final String username;
  bool selected = false;

  UserTile({
    this.userId,
    this.username,
    this.profileName,
    this.profileUrl,
  });

  factory UserTile.fromDocument(DocumentSnapshot doc) {
    return UserTile(
      userId: doc.data()['id'],
      profileName: doc.data()['profileName'],
      profileUrl: doc.data()['photoUrl'],
      username: doc.data()['userName'],
    );
  }

  @override
  _UserTileState createState() => _UserTileState(
        profileName: this.profileName,
        profileUrl: this.profileUrl,
        username: this.username,
        userId: this.userId,
        selected: this.selected,
      );
}

class _UserTileState extends State<UserTile> {
  final String profileName;
  final String profileUrl;
  final String username;
  final String userId;
  bool selected;

  _UserTileState({
    this.username,
    this.profileName,
    this.profileUrl,
    this.userId,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if (selected) {
          selected = false;
        } else {
          selected = true;
        }
        setState(() {
          addUsers.forEach((element) {
            if (element.userId == userId) {
              element.selected = selected;
            }
          });
        });
        addUsers.forEach((element) {
          print(element.selected);
        });
      },
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(profileUrl),
      ),
      trailing: selected
          ? Icon(
              Icons.select_all_outlined,
              color: Colors.green,
            )
          : null,
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
