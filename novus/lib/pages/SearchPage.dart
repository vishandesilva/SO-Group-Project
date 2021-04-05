import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong/latlong.dart';
import 'package:novus/models/user.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:novus/pages/PostScreenPage.dart';
import 'package:novus/pages/ProfilePage.dart';
import 'package:novus/widgets/PostTileWidget.dart';
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
            physics: NeverScrollableScrollPhysics(),
            children: [
              searchResults == null ? Container() : foundSearchResults(),
              Container(
                height: double.maxFinite,
                child: buildDiscoverTimeline(),
              ),
              buildMap()
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
      },
    );
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

  buildMap() {
    return FutureBuilder(
      future: getMarkers(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return circularProgress();

        return FlutterMap(
          options: new MapOptions(
            zoom: 2,
            maxZoom: 19,
            plugins: [
              MarkerClusterPlugin(),
            ],
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
            MarkerClusterLayerOptions(
              maxClusterRadius: 120,
              size: Size(40, 40),
              fitBoundsOptions: FitBoundsOptions(
                padding: EdgeInsets.all(50),
              ),
              markers: snapshot.data,
              polygonOptions: PolygonOptions(borderColor: Colors.purple[400], color: Colors.black12, borderStrokeWidth: 3),
              builder: (context, markers) {
                return FloatingActionButton(
                  child: Text(markers.length.toString()),
                  onPressed: null,
                );
              },
            ),
          ],
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

getMarkers(BuildContext context) async {
  List<String> userPostsList = [];
  List<Marker> markers = [];
  List<LatLng> points = [];
  List<Post> postsMap = [];
  List<Location> current = [];
  Marker currentMark;
  List<Post> posts = [];
  PostTile tile;

  QuerySnapshot userFollowingIds = await userReference.get();
  userFollowingIds.docs.forEach((element) {
    userPostsList.add(element.id);
  });

  //ignore: deprecated_member_use

  for (var i = 0; i < userPostsList.length; i++) {
    QuerySnapshot tempPosts = await postReference.doc(userPostsList[i]).collection('userPosts').get();
    posts.addAll(tempPosts.docs.map((e) => Post.fromDocument(e)).toList());
    tempPosts.docs.clear();
  }

  posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  for (int i = 0; i < posts.length; i++) {
    try {
      current = await locationFromAddress(posts[i].location);

      if (current != null) {
        try {
          currentMark = new Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(current[0].latitude, current[0].longitude),
            builder: (ctx) => Container(
              child: GestureDetector(
                onTap: () => openPost(posts[i].ownerId, posts[i].postId, context),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(posts[i].posturl),
                ),
              ),
            ),
          );
          markers.add(currentMark);
        } on NoSuchMethodError catch (e) {
          print(e);
        }
      }
    } on NoResultFoundException catch (e) {
      print(e);
    }
  }

  return markers;
}

openPost(String ownerId, String postId, BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PostScreenPage(
        userId: ownerId,
        postId: postId,
      ),
    ),
  );
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

class MarkersPosts {
  List<Marker> markers;
  List<String> posts;

  MarkersPosts(List<Marker> x, List<String> y) {
    this.markers = x;
    this.posts = y;
  }
}
