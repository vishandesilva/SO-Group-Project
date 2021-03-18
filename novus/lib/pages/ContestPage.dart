import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/PostScreenPage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/PostTileWidget.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ContestsPage extends StatefulWidget {
  @override
  _ContestsPageState createState() => _ContestsPageState();
}

class _ContestsPageState extends State<ContestsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Contest"),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "Your Current",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30.0),
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).accentColor,
                ),
                onPressed: null,
              )
            ],
          ),
          Divider(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 0.5,
                  color: Colors.purple,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text("Add Contest tiles here"),
            ),
          ),
        ],
      ),
    );
  }
}

class ContestTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        "Contest name",
      ),
    );
  }
}
