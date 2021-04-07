import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';

class TagsPosts extends StatefulWidget {
  final String tag;
  TagsPosts({this.tag});

  @override
  _TagsPostsState createState() => _TagsPostsState();
}

class _TagsPostsState extends State<TagsPosts> {
  List<Post> posts = [];
  bool isLoading = false;

  void initState() {
    super.initState();
    getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        title: Text(
          widget.tag,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder(
        future: getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return circularProgress();
          return ListView(
            children: snapshot.data,
          );
        },
      ),
    );
  }

  getPosts() async {
    List<String> userPostsList = [];

    QuerySnapshot userIdsSnapshot = await userReference.get();
    userIdsSnapshot.docs.forEach((element) {
      userPostsList.add(element.id);
    });

    List<Post> posts = [];
    for (var i = 0; i < userPostsList.length; i++) {
      QuerySnapshot tempPosts =
          await postReference.doc(userPostsList[i]).collection('userPosts').where('tags', arrayContains: widget.tag).get();

      posts.addAll(tempPosts.docs.map((e) => Post.fromDocument(e)).toList());
      tempPosts.docs.clear();
    }

    posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return posts;
  }
}
