import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/pages/PostScreenPage.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';

class ContestTimeline extends StatefulWidget {
  final String userId;
  final String contestId;
  final String profileName;

  ContestTimeline({
    this.profileName,
    this.userId,
    this.contestId,
  });

  @override
  _ContestTimelineState createState() => _ContestTimelineState();
}

class _ContestTimelineState extends State<ContestTimeline> {
  List<Post> posts = [];
  bool isLoading = false;

  void initState() {
    super.initState();
    getPosts();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        title: Text(
          "Posts by " + widget.profileName,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? circularProgress()
          : posts.isEmpty
              ? Center(
                  child: Container(
                    child: Text(
                      "No entries yet",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              : ListView(children: posts),
    );
  }

  getPosts() async {
    if (this.mounted) {
      setState(() {
        isLoading = true;
      });
    }
    QuerySnapshot snapshot2 =
        await contestReference.doc(widget.contestId).collection('partcipants').doc(widget.userId).collection('posts').get();
    List<String> tempIDs = [];
    List<Post> tempPosts = [];
    if (snapshot2.docs.isNotEmpty) {
      snapshot2.docs.forEach((element) {
        tempIDs.add(element.id);
      });

      for (var i = 0; i < tempIDs.length; i++) {
        DocumentSnapshot snapshot = await postReference.doc(widget.userId).collection('userPosts').doc(tempIDs[i]).get();
        tempPosts.add(Post.fromDocument(snapshot));
      }
    }
    if (this.mounted) {
      setState(() {
        posts = tempPosts;
        isLoading = false;
      });
    }
  }
}
