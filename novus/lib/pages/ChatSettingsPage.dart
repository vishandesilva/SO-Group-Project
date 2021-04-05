import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:uuid/uuid.dart';

List<UserTile> addUsers;

class ChatSettings extends StatefulWidget {
  final String chatId;
  final String name;
  final String chatUrl;

  ChatSettings({this.chatId, this.name, this.chatUrl});

  @override
  _ChatSettingsState createState() => _ChatSettingsState(chatUrl: chatUrl);
}

class _ChatSettingsState extends State<ChatSettings> {
  String chatUrl;

  _ChatSettingsState({this.chatUrl});

  TextEditingController chatTitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    chatTitleController.text = widget.name;
    return Scaffold(
      appBar: AppBar(
        title: GradientText(
          "Settings",
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor,
            ],
          ),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 25.0,
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => changeChatPhoto(),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: widget.chatUrl == "" ? null : CachedNetworkImageProvider(chatUrl),
                      ),
                    ),
                    Container(
                      width: 10.0,
                    ),
                    Expanded(
                      child: TextField(
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
                    ),
                  ],
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
                StreamBuilder(
                  stream: chatReference.doc(widget.chatId).get().asStream(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (!snapshot.hasData) return circularProgress();
                    List tempMembers = snapshot.data['members'];
                    return StreamBuilder(
                      stream: userReference.where('id', whereIn: tempMembers).get().asStream(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot2) {
                        if (!snapshot2.hasData) return circularProgress();
                        List<UserResult> comments = [];
                        snapshot2.data.docs.forEach((element) {
                          comments.add(UserResult(User.fromDocument(element)));
                        });
                        return Container(
                          child: ListView(
                            shrinkWrap: true,
                            children: comments,
                          ),
                        );
                      },
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

  changeChatPhoto() async {
    var imagePicker = ImagePicker();
    String postID = Uuid().v4();
    PickedFile tempImage =
        await imagePicker.getImage(source: ImageSource.gallery, maxHeight: 700, maxWidth: 900, imageQuality: 100);
    File croppedFile = await ImageCropper.cropImage(sourcePath: tempImage.path, compressQuality: 100, aspectRatioPresets: [
      CropAspectRatioPreset.square,
    ]);
    UploadTask uploadTask = storageReference.child("posts").child("chatphoto_$postID.jpg").putFile(croppedFile);
    String url = await (await uploadTask).ref.getDownloadURL().catchError((err) => "Photo didnt upload");

    chatReference.doc(widget.chatId).update({"chatUrl": url});
    setState(() {
      chatUrl = url;
    });
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
