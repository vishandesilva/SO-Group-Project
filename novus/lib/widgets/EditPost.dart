import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:novus/widgets/FlutterMap.dart';
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class EditPost extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String caption;
  final String posturl;
  final String contest;

  EditPost({
    this.postId,
    this.ownerId,
    this.contest,
    this.username,
    this.location,
    this.caption,
    this.posturl,
  });

  @override
  _EditPostState createState() => _EditPostState(
        postId: this.postId,
        ownerId: this.ownerId,
        caption: this.caption,
        location: this.location,
        posturl: this.posturl,
        username: this.username,
      );
}

class _EditPostState extends State<EditPost> {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String caption;
  final String posturl;

  _EditPostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.caption,
    this.posturl,
  });

  bool isUploading = false;
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  double lat;
  double long;

  @override
  void initState() {
    captionController.text = caption;
    locationController.text = location;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Edit post",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
              color: Theme.of(context).accentColor,
              size: 25.0,
            ),
            onPressed: isUploading
                ? null
                : () async {
                    setState(() => isUploading = true);
                    await postReference.doc(ownerId).collection('userPosts').doc(postId).update(
                      {
                        'caption': captionController.text,
                        'location': locationController.text,
                      },
                    );
                    setState(() => isUploading = false);
                    Navigator.pop(context);
                  },
          )
        ],
      ),
      body: isUploading
          ? circularProgress()
          : ListView(
              children: [
                Center(
                  child: Container(
                    padding: EdgeInsets.only(bottom: 10.0),
                    height: MediaQuery.of(context).size.height * 0.50,
                    width: MediaQuery.of(context).size.width,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: CachedNetworkImageProvider(posturl),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: Container(
                    width: 300,
                    child: Column(
                      children: [
                        TextField(
                          controller: captionController,
                          enabled: true,
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                          decoration: InputDecoration(
                            labelText: "Caption",
                            labelStyle: TextStyle(color: Theme.of(context).accentColor),
                            hintText: "Write a caption",
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                        ),
                        Divider(
                          height: 0.01,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextField(
                            controller: locationController,
                            enabled: true,
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                            decoration: InputDecoration(
                              labelText: "Location",
                              labelStyle: TextStyle(color: Theme.of(context).accentColor),
                              hintText: "Add location",
                              hintStyle: TextStyle(color: Colors.white38),
                            ),
                          ),
                        ),
                        Divider(
                          height: 0.01,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 70,
                        alignment: Alignment.center,
                        child: RaisedButton.icon(
                          label: Text(
                            "Pin location",
                            style: TextStyle(color: Colors.white),
                          ),
                          icon: Icon(
                            Icons.pin_drop_outlined,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          color: Theme.of(context).primaryColor,
                          onPressed: () => _getLocation(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  _getLocation() async {
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData userLocation;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    userLocation = await location.getLocation();
    lat = userLocation.latitude;
    long = userLocation.longitude;
    LatLng theLocation = LatLng(userLocation.latitude, userLocation.longitude);
    theLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlutterMapMake(lat: lat, long: long),
      ),
    );

    if (theLocation == null) {
      theLocation = LatLng(userLocation.latitude, userLocation.longitude);
    }

    List<geocoding.Placemark> placemarks =
        await geocoding.placemarkFromCoordinates(theLocation.latitude, theLocation.longitude, localeIdentifier: 'en');

    if (placemarks.isNotEmpty) {
      if (placemarks[0].locality != null && placemarks[0].locality != "") {
        setState(() {
          locationController.text = placemarks[0].locality + ", " + placemarks[0].country;
        });
      } else {
        setState(() {
          locationController.text = placemarks[0].country;
        });
      }
    } else if (placemarks.isEmpty) {
      theLocation = LatLng(userLocation.latitude, userLocation.longitude);
      placemarks = await geocoding.placemarkFromCoordinates(theLocation.latitude, theLocation.longitude, localeIdentifier: 'en');

      setState(() {
        locationController.text = placemarks[0].locality + ", " + placemarks[0].country;
      });
    }
  }
}
