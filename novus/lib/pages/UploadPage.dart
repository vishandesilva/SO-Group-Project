import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:image_picker/image_picker.dart';
import 'package:novus/models/user.dart';
import 'package:novus/widgets/HeaderWidget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as imageLib;
import 'package:novus/widgets/ProgressWidget.dart';
import 'package:photofilters/filters/preset_filters.dart';
import 'package:photofilters/photofilters.dart';
import 'package:uuid/uuid.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:location/location.dart';
import 'HomePage.dart';

class UploadPage extends StatefulWidget {
  final User userUpload;
  UploadPage({this.userUpload});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  // place holder for image
  File postImage;
  // generate random string for to use as id for posts
  String postID = Uuid().v4();
  // disable the post button to prevent spam
  bool isUploading = false;
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return postImage == null ? buildUploadScreen() : buildUploadFormScreen();
  }

  // use phone camera to take and upload a photo
  takePhoto() async {
    var imagePicker = ImagePicker();
    PickedFile tempImage = await imagePicker.getImage(
      source: ImageSource.camera,
      maxHeight: 700,
      maxWidth: 900,
      imageQuality: 100,
    );
    if (tempImage.path != null) {
      final image = FirebaseVisionImage.fromFilePath(tempImage.path);
      final faceDector = FirebaseVision.instance.faceDetector(
        FaceDetectorOptions(mode: FaceDetectorMode.accurate),
      );
      final result = await faceDector.processImage(image);
      if (result.isEmpty) {
        File tempFile = File(tempImage.path);
        String fileName = tempFile.path.split('/').last;
        var image = imageLib.decodeImage(tempFile.readAsBytesSync());
        Map imagefile = await Navigator.push(
          context,
          new MaterialPageRoute(
            builder: (context) => new PhotoFilterSelector(
              title: Text("Add Filters"),
              image: image,
              appBarColor: Colors.black,
              filters: presetFiltersList,
              filename: fileName,
              loader: Center(child: CircularProgressIndicator()),
              fit: BoxFit.contain,
            ),
          ),
        );

        if (imagefile != null && imagefile.containsKey('image_filtered')) {
          tempFile = imagefile['image_filtered'];
        }

        File croppedFile = await ImageCropper.cropImage(
          androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          sourcePath: tempFile.path,
          compressQuality: 100,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        );

        if (this.mounted)
          setState(() {
            postImage = croppedFile;
          });
        return;
      }
      SnackBar snackBar = SnackBar(
        content: Text('The selected image contains faces which are not allowed'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  // select existing picture from gallery
  galleryPhoto(BuildContext context) async {
    var imagePicker = ImagePicker();
    PickedFile tempImage = await imagePicker.getImage(
      source: ImageSource.gallery,
      maxHeight: 700,
      maxWidth: 900,
      imageQuality: 100,
    );

    if (tempImage != null) {
      final image = FirebaseVisionImage.fromFilePath(tempImage.path);
      final faceDector = FirebaseVision.instance.faceDetector(
        FaceDetectorOptions(mode: FaceDetectorMode.accurate),
      );

      final result = await faceDector.processImage(image);
      if (result.isEmpty) {
        File tempFile = File(tempImage.path);
        String fileName = tempFile.path.split('/').last;
        var image = imageLib.decodeImage(tempFile.readAsBytesSync());
        Map imagefile = await Navigator.push(
          context,
          new MaterialPageRoute(
            builder: (context) => new PhotoFilterSelector(
              title: Text("Add Filters"),
              image: image,
              appBarColor: Colors.black,
              filters: presetFiltersList,
              filename: fileName,
              loader: Center(child: CircularProgressIndicator()),
              fit: BoxFit.contain,
            ),
          ),
        );

        if (imagefile != null && imagefile.containsKey('image_filtered')) {
          tempFile = imagefile['image_filtered'];
        }

        File croppedFile = await ImageCropper.cropImage(
          androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          sourcePath: tempFile.path,
          compressQuality: 100,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        );

        if (this.mounted)
          setState(() {
            postImage = croppedFile;
          });
        return;
      }
      SnackBar snackBar = SnackBar(content: Text('The selected image contains faces which are not allowed'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  // upload process after "post" button is pressed
  Future<String> uploadPost(File postImage) async {
    UploadTask uploadTask = storageReference.child("posts").child("post_$postID.jpg").putFile(postImage);
    String url = await (await uploadTask).ref.getDownloadURL().catchError((err) => "Photo didnt upload");
    return url;
  }

  // compress image before storing in database
  compressImage() async {
    final tempDirectory = await getTemporaryDirectory();
    final path = tempDirectory.path;
    imageLib.Image tempImageFile = imageLib.decodeImage(postImage.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postID.jpg')..writeAsBytesSync(imageLib.encodeJpg(tempImageFile, quality: 85));
    setState(() => postImage = compressedImageFile);
  }

  //FIXME issue where location is denied and doesnt prompt for permission. geolocator doesnt work
  getLocation() async {
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

    List<geocoding.Placemark> placemarks =
        await geocoding.placemarkFromCoordinates(userLocation.latitude, userLocation.longitude, localeIdentifier: 'en');
    setState(() {
      locationController.text = placemarks[0].locality + ", " + placemarks[0].country;
      print(locationController.text);
    });
  }

  // send post to database
  void postToFireStore(String postUrl, String caption, String location) {
    DateTime timestamp = DateTime.now();
    postReference.doc(widget.userUpload.id).collection("userPosts").doc(postID).set({
      "postId": postID,
      "ownerId": widget.userUpload.id,
      "username": widget.userUpload.userName,
      "postUrl": postUrl,
      "caption": caption,
      "location": location,
      "timestamp": timestamp,
      "votes": {},
    });
  }

  // upload form to enter details once photo has been picked
  Scaffold buildUploadFormScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Caption",
          style: TextStyle(
            color: Colors.purple,
            fontSize: 25,
          ),
        ),
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => setState(() => postImage = null),
        ),
        actions: [
          TextButton(
            onPressed: isUploading
                ? null
                : () async {
                    setState(() => isUploading = true);
                    await compressImage();
                    String postUrl = await uploadPost(postImage);
                    postToFireStore(
                      postUrl,
                      captionController.text,
                      locationController.text,
                    );
                    captionController.clear();
                    setState(
                      () {
                        postImage = null;
                        isUploading = false;
                        postID = Uuid().v4();
                      },
                    );
                  },
            child: Text(
              "Post",
              style: TextStyle(
                color: Theme.of(context).accentColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                    height: MediaQuery.of(context).size.height * 0.55,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: FileImage(postImage),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(),
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
                            hintText: "Provide caption",
                            hintStyle: TextStyle(color: Theme.of(context).hintColor),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                        TextField(
                          controller: locationController,
                          enabled: true,
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                          decoration: InputDecoration(
                            hintText: "Provide location",
                            hintStyle: TextStyle(color: Theme.of(context).hintColor),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(user.url),
                  ),
                ),
                //TODO add google maps package to set location
                Container(
                  width: 200,
                  height: 70,
                  alignment: Alignment.center,
                  child: RaisedButton.icon(
                    label: Text(
                      "My Current Location",
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: Icon(
                      Icons.my_location_outlined,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    color: Theme.of(context).primaryColor,
                    onPressed: () => getLocation(),
                  ),
                )
              ],
            ),
    );
  }

  // initial screen to upload a photo
  Scaffold buildUploadScreen() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, title: 'Post Photo', enableBackButton: true),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 100.0,
                color: Theme.of(context).buttonColor,
              ),
              Padding(
                padding: EdgeInsets.all(14.0),
                child: Container(
                  width: 200.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 4.0),
                    borderRadius: BorderRadius.circular(20),
                    //border:
                  ),
                  child: TextButton(
                    onPressed: () => takePhoto(),
                    child: Text(
                      "Take a Photo",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(14.0),
                child: Container(
                  width: 200.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 4.0),
                    borderRadius: BorderRadius.circular(20),
                    //border:
                  ),
                  child: TextButton(
                    onPressed: () => galleryPhoto(context),
                    child: Text(
                      "From Gallery",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
