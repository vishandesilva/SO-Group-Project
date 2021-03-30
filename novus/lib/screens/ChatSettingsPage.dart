import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';

List<UserTile> addUsers;

class ChatSettings extends StatefulWidget {
  final String chatId;
  final String name;

  ChatSettings({this.chatId, this.name});

  @override
  _ChatSettingsState createState() => _ChatSettingsState();
}

class _ChatSettingsState extends State<ChatSettings> {
  TextEditingController chatTitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    chatTitleController.text = widget.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onSubmitted: (value) => chatReference.doc(widget.chatId).update({'name': chatTitleController.text}),
                  controller: chatTitleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: "Group name",
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
                TextButton(
                  onPressed: () => addMember(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 35.0,
                        ),
                        Text(
                          "Add People",
                          style: TextStyle(color: Colors.white, fontSize: 15.0),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  height: 0.1,
                ),
                FutureBuilder(
                  future: getChatMembers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return circularProgress();
                    return Container(
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
        ],
      ),
    );
  }

  addMember() {
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
                    "Add members to ",
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
                    chatReference.doc(widget.chatId).update({
                      'members': FieldValue.arrayUnion([element.userId])
                    });
                  }
                });
                addUsers.clear();
                setState(() {});
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

    List<String> members = [];
    await chatReference.doc(widget.chatId).get().then(
          (value) => List.from(value.data()['members']).forEach(
            (element) {
              members.add(element);
            },
          ),
        );

    for (var i = 0; i < tempIDs.length; i++) {
      if (!members.contains(tempIDs[i])) {
        DocumentSnapshot usersfoll = await userReference.doc(tempIDs[i]).get();
        comments.add(UserTile.fromDocument(usersfoll));
      }
    }
    addUsers = comments;
    return comments;
  }

  getChatMembers() async {
    List<String> members = [];
    await chatReference.doc(widget.chatId).get().then(
          (value) => List.from(value.data()['members']).forEach(
            (element) {
              members.add(element);
            },
          ),
        );

    List<UserResult> comments = [];
    for (var i = 0; i < members.length; i++) {
      DocumentSnapshot usersfoll = await userReference.doc(members[i]).get();
      comments.add(UserResult(User.fromDocument(usersfoll)));
    }
    return comments;
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
