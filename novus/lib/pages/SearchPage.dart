import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/widgets/PostWidget.dart';
import 'package:novus/widgets/ProgressWidget.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin<SearchPage> {
  // controller for the textfield
  TextEditingController textEditingController = TextEditingController();
  // place holder for user profiles to display on search screen
  Stream<QuerySnapshot> searchResults;
  // keeps state alive when user switches screens
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(text: "Accounts"),
              Tab(text: "Discover"),
              Tab(text: "Map View"),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          brightness: Brightness.dark,
          title: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: TextFormField(
                controller: textEditingController,
                onFieldSubmitted: performSearch,
                cursorColor: Colors.white,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.0,
                  decoration: TextDecoration.none,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                  hintText: "Search accounts",
                  filled: true,
                  prefixIcon: Icon(
                    Icons.search_outlined,
                    color: Colors.white,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white,
                    ),
                    onPressed: textEditingController.clear,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () => WidgetsBinding.instance.focusManager.primaryFocus?.unfocus(),
          child: TabBarView(
            children: [
              searchResults == null ? Container() : foundSearchResults(),
              Container(
                height: double.maxFinite,
                child: buildDiscoverTimeline(),
              ),
              Icon(Icons.ac_unit)
            ],
          ),
        ),
      ),
    );
  }

  // builds the results from query to dispplay
  //TODO add screen when there is no search results
  foundSearchResults() {
    return StreamBuilder(
        stream: searchResults,
        builder: (context, currentSnapshot) {
          if (!currentSnapshot.hasData) {
            return circularProgress();
          }
          if (searchResults.first != null) {
            List<UserResult> searchedResults = [];
            currentSnapshot.data.docs.forEach(
              (document) => searchedResults.add(
                UserResult(
                  User.fromDocument(document),
                ),
              ),
            );
            return ListView(children: searchedResults);
          } else {
            return Text(
              "Fsfsfsf",
              style: TextStyle(color: Colors.white),
            );
          }
        });
  }

  //TODO if search cant be found
  // initial screen that user sees when opening the search page
  noSearchResults() {
    return ListView(
      shrinkWrap: true,
      children: [
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 200),
          child: Text(
            'Search For Users',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 40),
          ),
        ),
      ],
    );
  }

  // query the database for usernames on submission in textfield
  performSearch(String searchName) {
    Stream<QuerySnapshot> allUsers = userReference.where('profileName', isGreaterThanOrEqualTo: searchName).snapshots();
    if (this.mounted) setState(() => searchResults = allUsers);
  }

  buildDiscoverTimeline() {
    return FutureBuilder(
      future: getPosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return circularProgress();
        return ListView(
          children: snapshot.data,
        );
      },
    );
  }

  getPosts() async {
    List<String> userPostsList = [];

    QuerySnapshot userFollowingIds = await userReference.get();
    userFollowingIds.docs.forEach((element) {
      userPostsList.add(element.id);
    });

    //ignore: deprecated_member_use
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

// class to build userprofile represented on the search screen
class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Theme.of(context).cardColor.withOpacity(0.75),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => showProfile(context),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(user.url),
                ),
                title: Text(
                  user.profileName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  user.userName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12.0,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  showProfile(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          userid: user.id,
        ),
      ),
    );
  }
}
