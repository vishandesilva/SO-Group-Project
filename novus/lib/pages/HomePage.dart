import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/ContestPage.dart';
import 'package:novus/pages/CreateAccountPage.dart';
import 'package:novus/pages/NotificationsPage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/pages/SearchPage.dart';
import 'package:novus/pages/TimeLinePage.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';

// using Googles Authentication package to validate users on the application
final GoogleSignIn googleSignIn = GoogleSignIn();
// reference point to database consisting of all users on the platform
final userReference = FirebaseFirestore.instance.collection("users");
final postReference = FirebaseFirestore.instance.collection("posts");
final commentsReference = FirebaseFirestore.instance.collection("comments");
final notificationsReference = FirebaseFirestore.instance.collection("notifications");
final contestReference = FirebaseFirestore.instance.collection("contests");
final chatReference = FirebaseFirestore.instance.collection("chats");
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
  PersistentTabController _controller = PersistentTabController(initialIndex: 0);

  @override
  Widget build(BuildContext context) {
    if (userSignedIn)
      return buildHomeScreen(context);
    else
      return buildSignInScreen();
  }

  Widget buildHomeScreen(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      decoration: NavBarDecoration(border: Border(top: BorderSide(width: 0.15, color: Colors.white))),
      backgroundColor: Colors.black, // Default is Colors.white.
      handleAndroidBackButtonPress: true, // Default is true.
      resizeToAvoidBottomInset:
          true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
      stateManagement: true, // Default is true.
      hideNavigationBarWhenKeyboardShows:
          true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: ItemAnimationProperties(
        // Navigation Bar's items animation properties.
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: ScreenTransitionAnimation(
        // Screen transition animation on change of selected tab.
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style1, // Choose the nav bar style with this property.
    );
  }

  List<Widget> _buildScreens() {
    return [
      TimeLinePage(),
      SearchPage(),
      ContestsPage(
        userId: user.id,
      ),
      NotificationsPage(),
      ProfilePage(userid: user.id),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(CupertinoIcons.home),
        title: ("Home"),
        activeColorPrimary: Theme.of(context).accentColor,
        inactiveColorPrimary: CupertinoColors.white,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(CupertinoIcons.search),
        title: ("Search"),
        activeColorPrimary: Theme.of(context).accentColor,
        inactiveColorPrimary: CupertinoColors.white,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.emoji_events_outlined),
        title: ("Contests"),
        activeColorPrimary: Theme.of(context).accentColor,
        inactiveColorPrimary: CupertinoColors.white,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.notifications_outlined),
        title: ("Activity"),
        activeColorPrimary: Theme.of(context).accentColor,
        inactiveColorPrimary: CupertinoColors.white,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(CupertinoIcons.profile_circled),
        title: ("Profile"),
        activeColorPrimary: Theme.of(context).accentColor,
        inactiveColorPrimary: CupertinoColors.white,
      ),
    ];
  }

  Scaffold buildSignInScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image(image: AssetImage("assets/images/novus-logo.png"), height: 75.0),
                  GradientText(
                    "OVUS",
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
                      fontSize: 75.0,
                    ),
                  ),
                ],
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
    //pageController = PageController();

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
    //pageController.dispose();
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
        'points': 0,
        //'dateCreated': timeStamp
      });
      documentSnapshot = await userReference.doc(googleSignInAccount.id).get();
    }
    user = User.fromDocument(documentSnapshot);
  }
}
