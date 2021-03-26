import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/UploadPage.dart';

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
    title: Text(
      appTitle ? "Novus" : title,
      style: TextStyle(
        color: Colors.purple,
        //TODO decide on fonts
        fontFamily: appTitle ? "Signatra" : "",
        fontSize: appTitle ? 35.0 : 25.0,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    actions: enableActionButton
        ? <Widget>[
            IconButton(
              padding: const EdgeInsets.only(top: 10.0, right: 15.0),
              icon: Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 30.0,
              ),
              onPressed: null,
            ),
            IconButton(
              padding: const EdgeInsets.only(top: 10.0, right: 20.0),
              icon: Icon(
                Icons.photo_camera_outlined,
                color: Colors.white,
                size: 30.0,
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (context) => UploadPage(
                      userUpload: user,
                    ),
                  ),
                );
              },
            )
          ]
        : null,
  );
}
