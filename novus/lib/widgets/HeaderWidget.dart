import 'package:flutter/material.dart';
import 'package:novus/pages/NotificationsPage.dart';

// reusable Appbar widget for pages
AppBar header(BuildContext context,
    {bool appTitle = false, String title, bool enableBackButton = false, enableActionButton = false}) {
  return AppBar(
      iconTheme: Theme.of(context).iconTheme,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      brightness: Brightness.dark,
      automaticallyImplyLeading: enableBackButton ? false : true,
      title: Text(
        appTitle ? "Novus" : title,
        style: TextStyle(
          color: Colors.purple,
          // ignore: todo
          fontFamily: appTitle ? "" : "", //TODO decide on fonts
          fontSize: appTitle ? 50.0 : 25.0,
        ), //
        overflow: TextOverflow.ellipsis,
      ),
      actions: enableActionButton
          ? <Widget>[
              IconButton(
                  padding: const EdgeInsets.only(top: 11.0, right: 5.0),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 37.0,
                  ),
                  onPressed: null),
              IconButton(
                padding: const EdgeInsets.only(top: 11.0, right: 10.0),
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 37.0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsPage(),
                    ),
                  );
                },
              )
            ]
          : null);
}
