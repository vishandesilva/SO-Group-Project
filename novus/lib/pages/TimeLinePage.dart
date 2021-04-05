import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';

class TimeLinePage extends StatefulWidget {
  @override
  _TimeLinePageState createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage> {
  void initState() {
    super.initState();
    getPosts();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, appTitle: true, enableActionButton: true),
      body: FutureBuilder(
        future: getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return circularProgress();
          return RefreshIndicator(
            onRefresh: () => _refreshData(),
            child: ListView(
              children: snapshot.data,
            ),
          );
        },
      ),
    );
  }

  Future _refreshData() async {
    //await Future.delayed(Duration(seconds: 3));
    setState(() {});
  }

  getPosts() async {
    List<String> userPostsList = [user.id];

    QuerySnapshot userFollowingIds = await userReference.doc(user.id).collection('following').get();
    userFollowingIds.docs.forEach((element) {
      userPostsList.add(element.id);
    });

    List<Post> posts = [];
    for (var i = 0; i < userPostsList.length; i++) {
      QuerySnapshot tempPosts = await postReference.doc(userPostsList[i]).collection('userPosts').get();
      posts.addAll(tempPosts.docs.map((e) => Post.fromDocument(e)).toList());
      tempPosts.docs.clear();
    }

    posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return posts;
  }
}
