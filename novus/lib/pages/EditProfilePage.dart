import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import "package:flutter/material.dart";
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:uuid/uuid.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;
  EditProfilePage({this.userId});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController profileNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  final GlobalKey _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  bool _bioValid = true;
  bool _profileName = true;
  bool _userName = true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() => isLoading = true);
    DocumentSnapshot userSnapshot = await userReference.doc(widget.userId).get();
    user = User.fromDocument(userSnapshot);
    profileNameController.text = user.profileName;
    bioController.text = user.bio;
    userNameController.text = user.userName;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        automaticallyImplyLeading: true,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.purple,
            fontSize: 25.0,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.done,
              color: Theme.of(context).iconTheme.color,
              size: 30.0,
            ),
            onPressed: () => updateProfileInfo(),
          ),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(user.url),
                        radius: 45.0,
                      ),
                    ),
                    TextButton(
                      onPressed: changeProfilePicture,
                      child: Text(
                        "Change Profile Picture",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Profile Name",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextField(
                            controller: profileNameController,
                            decoration: InputDecoration(
                              hintText: "New Profile Name",
                              hintStyle: TextStyle(color: Colors.white38),
                              errorText: !_profileName ? "Name too Short" : null,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            cursorColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Username",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextField(
                            controller: userNameController,
                            decoration: InputDecoration(
                              hintText: "Your Username",
                              hintStyle: TextStyle(color: Colors.white38),
                              errorText: !_userName ? "Username is either too long or too short" : null,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            cursorColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bio",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextField(
                            controller: bioController,
                            decoration: InputDecoration(
                              hintText: "About Yourself",
                              hintStyle: TextStyle(color: Colors.white38),
                              errorText: !_bioValid ? "Bio is too long" : null,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            cursorColor: Colors.white,
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
    );
  }

  updateProfileInfo() {
    setState(
      () {
        if (profileNameController.text.trim().length < 4 || profileNameController.text.isEmpty) {
          _profileName = false;
        } else {
          _profileName = true;
        }

        if (userNameController.text.trim().length > 13 ||
            userNameController.text.trim().length < 4 ||
            userNameController.text.isEmpty) {
          _userName = false;
        } else {
          _userName = true;
        }

        if (bioController.text.trim().length > 150) {
          _bioValid = false;
        } else {
          _bioValid = true;
        }
      },
    );

    if (_profileName && _bioValid && _userName) {
      userReference.doc(widget.userId).update({
        "profileName": profileNameController.text,
        "bio": bioController.text,
        "userName": userNameController.text,
      });

      //FIXME get snackbar to work
      // SnackBar snackBar = SnackBar(content: Text('Welcome  to Novus'));
      // // ignore: deprecated_member_use
      // Scaffold.of(context).showSnackBar(snackBar);
      Timer(Duration(seconds: 2), () => Navigator.pop(context));
    }
  }

  changeProfilePicture() async {
    var imagePicker = ImagePicker();
    String postID = Uuid().v4();
    PickedFile tempImage =
        await imagePicker.getImage(source: ImageSource.gallery, maxHeight: 700, maxWidth: 900, imageQuality: 100);
    File croppedFile = await ImageCropper.cropImage(sourcePath: tempImage.path, compressQuality: 100, aspectRatioPresets: [
      CropAspectRatioPreset.square,
    ]);
    UploadTask uploadTask = storageReference.child("posts").child("post_$postID.jpg").putFile(croppedFile);
    String url = await (await uploadTask).ref.getDownloadURL().catchError((err) => "Photo didnt upload");
    userReference.doc(user.id).update({"photoUrl": url});

    DocumentSnapshot snapshot = await userReference.doc(user.id).get();
    user = User.fromDocument(snapshot);
  }
}
