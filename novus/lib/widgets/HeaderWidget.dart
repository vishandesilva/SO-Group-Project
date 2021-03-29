import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/UploadPage.dart';
import 'package:novus/screens/home_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';

// reusable Appbar widget for pages
AppBar header(BuildContext context,
    {bool appTitle = false, String title, bool enableBackButton = false, enableActionButton = false}) {
  return AppBar(
    iconTheme: Theme.of(context).iconTheme,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    brightness: Brightness.dark,
    automaticallyImplyLeading: enableBackButton ? false : true,
    bottom: appTitle
        ? PreferredSize(
            child: Container(
              color: Colors.white,
              height: 0.045,
            ),
            preferredSize: Size.fromHeight(4.0),
          )
        : null,
    title: appTitle
        ? Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image(image: AssetImage("assets/images/novus-logo.png"), height: 35.0),
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
                    fontSize: 35.0,
                  ),
                ),
              ],
            ),
          )
        : Text(
            appTitle ? "Novus" : title,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 25.0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
    actions: enableActionButton
        ? <Widget>[
            IconButton(
                padding: const EdgeInsets.only(top: 10.0, right: 15.0),
                icon: Icon(
                  CupertinoIcons.chat_bubble_text,
                  color: Colors.white,
                  size: 30.0,
                ),
                onPressed: () {
                  pushNewScreen(
                    context,
                    screen: ChatPage(),
                    withNavBar: true, // OPTIONAL VALUE. True by default.
                    pageTransitionAnimation: PageTransitionAnimation.fade,
                  );
                }),
            IconButton(
              padding: const EdgeInsets.only(top: 10.0, right: 20.0),
              icon: Icon(
                CupertinoIcons.camera,
                color: Colors.white,
                size: 30.0,
              ),
              onPressed: () {
                pushNewScreen(
                  context,
                  screen: UploadPage(
                    userUpload: user,
                  ),
                  withNavBar: true, // OPTIONAL VALUE. True by default.
                  pageTransitionAnimation: PageTransitionAnimation.fade,
                );
              },
            )
          ]
        : null,
  );
}
