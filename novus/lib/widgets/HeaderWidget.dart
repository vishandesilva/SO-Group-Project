import 'package:flutter/material.dart';

// reusable Appbar widget for pages
AppBar header(BuildContext context, {bool appTitle = false, String title, bool enableBackButton = false}) {
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
  );
}
