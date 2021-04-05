import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong/latlong.dart';
import 'package:novus/plugins/dragmarker.dart';
import 'package:novus/pages/UploadPage.dart';

class FlutterMapMake extends StatefulWidget {
  double lat;
  double long;
  FlutterMapMake({this.lat, this.long});
  @override
  _FlutterMapMakeState createState() => new _FlutterMapMakeState();
}

class _FlutterMapMakeState extends State<FlutterMapMake> {
  LatLng coordinates = LatLng(0, 0);
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      //App Bar ----------------------------
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        title: Text("Choose location",
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
            )),
        backgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      //App Bar ---------------------------

      //Map---------------------------------
      body: FlutterMap(
          options: MapOptions(center: LatLng(widget.lat, widget.long), zoom: 8, maxZoom: 19, plugins: [
            DragMarkerPlugin(),
          ]),
          children: [
            TileLayerWidget(
              options: TileLayerOptions(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                maxZoom: 19,
              ),
            ),
            LocationMarkerLayerWidget(
              options: LocationMarkerLayerOptions(
                marker: DefaultLocationMarker(
                  color: Colors.green,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                markerSize: const Size(40, 40),
                accuracyCircleColor: Colors.green.withOpacity(0.1),
                headingSectorColor: Colors.green.withOpacity(0.8),
                headingSectorRadius: 120,
                markerAnimationDuration: Duration.zero, // disable animation
              ),
            ),
          ],
          layers: [
            DragMarkerPluginOptions(
              markers: [
                DragMarker(
                  point: LatLng(widget.lat, widget.long),
                  width: 80.0,
                  height: 80.0,
                  offset: Offset(0.0, -8.0),
                  builder: (ctx) => Container(child: Icon(Icons.location_on, size: 50)),
                  onDragStart: (details, point) => print("Start point $point"),
                  onDragEnd: (details, point) => {print("End point $point"), coordinates = point},
                  onDragUpdate: (details, point) {},
                  onTap: (point) {
                    print("on tap");
                  },
                  onLongPress: (point) {
                    print("on long press");
                  },
                  feedbackBuilder: (ctx) => Container(child: Icon(Icons.edit_location, size: 75)),
                  feedbackOffset: Offset(0.0, -18.0),
                  updateMapNearEdge: true, // Experimental, move the map when marker close to edge
                  nearEdgeRatio: 2.0, // Experimental
                  nearEdgeSpeed: 1.0, // Experimental
                )
              ],
            )
          ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, coordinates);
        },
        child: const Icon(Icons.edit),
        backgroundColor: Colors.purple,
      ),
    );
    //Map---------------------------------
  }
}

class SimpleMapMake extends StatefulWidget {
  double lat;
  double long;
  String photoLocation;

  SimpleMapMake({this.lat, this.long, this.photoLocation});

  @override
  _SimpleMapMakeState createState() => new _SimpleMapMakeState();
}

class _SimpleMapMakeState extends State<SimpleMapMake> {
  LatLng coordinates = LatLng(0, 0);
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      //App Bar ----------------------------
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        title: Text(widget.photoLocation,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
            )),
        backgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      //App Bar ---------------------------

      //Map---------------------------------
      body: FlutterMap(
          options: MapOptions(center: LatLng(widget.lat, widget.long), zoom: 4, maxZoom: 19, plugins: [
            DragMarkerPlugin(),
          ]),
          children: [
            TileLayerWidget(
              options: TileLayerOptions(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                maxZoom: 19,
              ),
            ),
          ],
          layers: [
            MarkerLayerOptions(
              markers: [
                Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(widget.lat, widget.long),
                    builder: (ctx) => Container(child: Icon(Icons.location_on, size: 50))),
              ],
            )
          ]),
    );
    //Map---------------------------------
  }
}
