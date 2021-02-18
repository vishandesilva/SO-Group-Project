import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/CreateAccountPage.dart';
import 'package:novus/pages/NotificationsPage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/pages/SearchPage.dart';
import 'package:novus/pages/TimeLinePage.dart';
import 'package:novus/pages/UploadPage.dart';

// using Googles Authentication package to validate users on the application
final GoogleSignIn googleSignIn = GoogleSignIn();
// reference point to database consisting of all users on the platform
final userReference = FirebaseFirestore.instance.collection("users");
final postReference = FirebaseFirestore.instance.collection("posts");
final commentsReference = FirebaseFirestore.instance.collection("comments");
final notificationsReference = FirebaseFirestore.instance.collection("notifications");
// reference point to firbase storage consisting of all media files
final Reference storageReference = FirebaseStorage.instance.ref();
// place holder for the current user details
User user;
bool userSignedIn = false;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageController pageController;
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (userSignedIn)
      return buildHomeScreen();
    else
      return buildSignInScreen();
  }

  Scaffold buildHomeScreen() {
    return Scaffold(
      body: PageView(
        children: [
          TimeLinePage(),
          SearchPage(),
          UploadPage(
            userUpload: user,
          ),
          NotificationsPage(),
          ProfilePage(userid: user.id),
        ],
        controller: pageController,
        onPageChanged: (index) => setState(() => this.currentPageIndex = index),
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications)),
          BottomNavigationBarItem(icon: Icon(Icons.person)),
        ],
        currentIndex: currentPageIndex,
        onTap: (index) => pageController.jumpToPage(index),
        activeColor: Colors.deepPurple,
        inactiveColor: Colors.white,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }

  Scaffold buildSignInScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Novus",
              style: TextStyle(
                color: Colors.deepPurple[700],
                fontSize: 80,
                // ignore: todo
                fontFamily: '', //TODO add font later
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).accentColor),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(image: AssetImage("assets/images/google_logo.png"), height: 25.0),
                  TextButton(
                    onPressed: () => loginUser(),
                    child: RichText(
                      text: TextSpan(
                        text: 'Sign In via',
                        children: [
                          TextSpan(text: ' Google', style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void initState() {
    super.initState();
    pageController = PageController();

    //handle user changes and when a user logs in
    googleSignIn.onCurrentUserChanged.listen(
      (event) => controlSignIn(event),
      onError: (err) => print("Error msg" + err.toString()),
    );
    // prevent logging in everytime the app is opened
    if (userSignedIn)
      googleSignIn
          .signInSilently(suppressErrors: false)
          .then((value) => controlSignIn(value))
          .catchError((err) => print("Error msg: " + err.toString()));
  }

  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  controlSignIn(GoogleSignInAccount googleSignInAccount) async {
    if (googleSignInAccount != null) {
      await userInfoToFirestore();
      setState(() => userSignedIn = true);
    } else {
      setState(() => userSignedIn = false);
    }
  }

  logoutUser() => googleSignIn.signOut();

  loginUser() => googleSignIn.signIn();

  userInfoToFirestore() async {
    final GoogleSignInAccount googleSignInAccount = googleSignIn.currentUser;
    DocumentSnapshot documentSnapshot = await userReference.doc(googleSignInAccount.id).get();
    String userName;
    if (!documentSnapshot.exists) {
      do {
        // push a signup screen to enter a desired user name
        userName = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateAccountPage(),
          ),
        );
      } while (userName == null);

      userReference.doc(googleSignInAccount.id).set({
        'id': googleSignInAccount.id,
        'profileName': googleSignInAccount.displayName,
        'userName': userName,
        'email': googleSignInAccount.email,
        'photoUrl': googleSignInAccount.photoUrl,
        'bio': '',
        //'dateCreated': timeStamp
      });
      documentSnapshot = await userReference.doc(googleSignInAccount.id).get();
    }
    user = User.fromDocument(documentSnapshot);
  }
}
