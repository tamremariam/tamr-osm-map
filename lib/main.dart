import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:tuple/tuple.dart';
//----------------------------------------------------------------

import 'package:osrm/osrm.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

//----------------------------------------------------------------
class CustomMarker {
  final String name;
  final LatLng position;

  CustomMarker(this.name, this.position);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  static const _useTransformerId = 'useTransformerId';

  final markers = ValueNotifier<List<AnimatedMarker>>([]);
  final center = const LatLng(9.307519939764234, 42.125973344740515);

  // bool _useTransformer = true;
  int _lastMovedToMarkerIndex = -1;

  late final _animatedMapController = AnimatedMapController(vsync: this);
  List<CustomMarker> customMarkers = [];
  late Timer timer;
  bool _followLocation = false;
  var polypoints = <LatLng>[];
  // Example array of tuples

  @override
  void initState() {
    super.initState();
    getRoute();

    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      updateCustomMarkers();
    });
  }

  @override
  void dispose() {
    markers.dispose();
    _animatedMapController.dispose();
    super.dispose();
  }

  List<CustomMarker> getSharedMarkers() {
    return [
      CustomMarker('Chad', LatLng(9.310118436123041, 42.124504544137146)),
      CustomMarker('Nigeria', LatLng(9.311075330917536, 42.11970723201347)),
      CustomMarker('DRC', LatLng(9.301707721823323, 42.126954235434326)),
      CustomMarker('CAR', LatLng(9.30367191871694, 42.111847805768306)),
      CustomMarker('Sudan', LatLng(9.321449916744617, 42.12430040319571)),
      CustomMarker('Kenya', LatLng(9.31928437331062, 42.112817475240114)),
      CustomMarker('Zambia', LatLng(9.309312627948243, 42.12593353072717)),
      CustomMarker('Egypt', LatLng(9.308053548956083, 42.11751271689307)),
      CustomMarker('Algeria', LatLng(9.313492737674148, 42.12399419178357)),
    ];
  }

  void updateCustomMarkers() {
    // Clear and update the markers
    customMarkers = List<CustomMarker>.from(getSharedMarkers());
    // Add more markers or update existing ones
    setState(() {});
  }

  num distance = 0.0;
  num duration = 0.0;

  Future<void> getRoute() async {
    final osrm = Osrm();
    final options = RouteRequest(
      coordinates: [
        (42.12430040319571, 9.321449916744617),
        (42.126954235434326, 9.301707721823323),
        (42.111847805768306, 9.30367191871694),
      ],
      overview: OsrmOverview.full,
    );

    try {
      final route = await osrm.route(options);
      distance = route.routes.first.distance!;
      duration = route.routes.first.duration!;
      polypoints =
          route.routes.first.geometry!.lineString!.coordinates.map((e) {
        var location = e.toLocation();
        return LatLng(location.lat, location.lng);
      }).toList();

      if (kDebugMode) {
        // print(polypoints); // print the points in the debug format
      }

      setState(() {});
    } catch (e) {
      print("Error fetching route: $e");

      // Handle the error
      // For now, let's print the error and leave the UI unchanged
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<List<AnimatedMarker>>(
        valueListenable: markers,
        builder: (context, markers, _) {
          return FlutterMap(
            mapController: _animatedMapController.mapController,
            options: MapOptions(
              initialCenter: center,
              onTap: (_, point) => _addMarker(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
                tileUpdateTransformer: _animatedMoveTileUpdateTransformer,
                tileProvider: CancellableNetworkTileProvider(),
              ),
              // TileLayer(
              //   wmsOptions: WMSTileLayerOptions(
              //     baseUrl: 'https://{s}.s2maps-tiles.eu/wms/?',
              //     layers: const ['s2cloudless-2021_3857'],
              //   ),
              //   subdomains: const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
              //   userAgentPackageName: 'dev.fleaflet.flutter_map.example',
              //   tileUpdateTransformer: _animatedMoveTileUpdateTransformer,
              //   tileProvider: CancellableNetworkTileProvider(),
              // ),
              AnimatedMarkerLayer(markers: markers),
              CurrentLocationLayer(
                // Customize the marker style
                style: LocationMarkerStyle(
                  markerSize: const Size(40, 40),
                  marker: const Icon(
                    Icons.circle,
                    color: Colors.blue,
                  ),
                ),
                // Follow location updates
                // Follow location updates only when _followLocation is true
                followOnLocationUpdate: _followLocation
                    ? FollowOnLocationUpdate.always
                    : FollowOnLocationUpdate.never,
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polypoints, // Wrap polypoints in another list
                    strokeWidth: 4.0,
                    color: Colors.grey,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (polypoints.isNotEmpty)
                    Marker(
                      rotate: true,
                      width: 100.0,
                      height: 40.0,
                      point: polypoints[
                          math.max(0, (polypoints.length / 2).floor())],
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${distance.toStringAsFixed(2)} m',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  for (var marker in customMarkers)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: marker.position,
                      // Wrap the Icon with GestureDetector
                      child: GestureDetector(
                        onTap: () => onMarkerTap(marker),
                        child: const Icon(
                          Icons.local_taxi,
                          color: Color.fromARGB(255, 1, 1, 1),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: SeparatedColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        separator: const SizedBox(height: 8),
        children: [
          FloatingActionButton(
            onPressed: () {
              markers.value = [];
              polypoints = [];
              _animatedMapController.animateTo(
                dest: center,
                // rotation: 0,
                // customId: _useTransformer ? _useTransformerId : null,
              );
            },
            tooltip: 'Clear modifications',
            child: const Icon(Icons.clear_all),
          ),
          FloatingActionButton(
            onPressed: () => _animatedMapController.animatedZoomIn(
                // customId: _useTransformer ? _useTransformerId : null,
                ),
            tooltip: 'Zoom in',
            child: const Icon(Icons.zoom_in),
          ),
          FloatingActionButton(
            onPressed: () => _animatedMapController.animatedZoomOut(
                // customId: _useTransformer ? _useTransformerId : null,
                ),
            tooltip: 'Zoom out',
            child: const Icon(Icons.zoom_out),
          ),
          FloatingActionButton(
            tooltip: 'Center on markers',
            onPressed: () {
              if (markers.value.length < 2) return;

              final points = markers.value.map((m) => m.point).toList();
              _animatedMapController.animatedFitCamera(
                cameraFit: CameraFit.coordinates(
                  coordinates: points,
                  padding: const EdgeInsets.all(50),
                ),
                rotation: 0,
                // customId: _useTransformer ? _useTransformerId : null,
              );
            },
            child: const Icon(Icons.center_focus_strong),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                tooltip: 'Move to previes marker',
                onPressed: () {
                  if (markers.value.isEmpty) return;

                  final points = markers.value.map((m) => m.point);
                  setState(
                    () => _lastMovedToMarkerIndex =
                        (_lastMovedToMarkerIndex - 1) % points.length,
                  );

                  _animatedMapController.animateTo(
                    dest: points.elementAt(_lastMovedToMarkerIndex),
                    // customId: _useTransformer ? _useTransformerId : null,
                    offset: const Offset(100, 100),
                  );
                },
                child: const Icon(Icons.skip_previous),
              ),
              const SizedBox.square(dimension: 8),
              FloatingActionButton(
                tooltip: 'Move to next marker',
                onPressed: () {
                  if (markers.value.isEmpty) return;

                  final points = markers.value.map((m) => m.point);
                  setState(
                    () => _lastMovedToMarkerIndex =
                        (_lastMovedToMarkerIndex + 1) % points.length,
                  );

                  _animatedMapController.animateTo(
                    dest: points.elementAt(_lastMovedToMarkerIndex),
                    // customId: _useTransformer ? _useTransformerId : null,
                  );
                },
                child: const Icon(Icons.skip_next),
              ),
            ],
          ),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _followLocation = !_followLocation;
                _animatedMapController.animateTo(zoom: 18);
                // Toggle the follow location flag
              });
            },
            child: Icon(
              _followLocation ? Icons.explore : Icons.my_location,
            ),
          ),
          FloatingActionButton(
            tooltip: 'directions',
            onPressed: () {
              getRoute();
              if (markers.value.length < 2) return;

              final points = markers.value.map((m) => m.point).toList();
              _animatedMapController.animatedFitCamera(
                cameraFit: CameraFit.coordinates(
                  coordinates: points,
                  padding: const EdgeInsets.all(12),
                ),
                rotation: 0,
                // customId: _useTransformer ? _useTransformerId : null,
              );

              // Print the coordinates of markers
              for (int i = 0; i < points.length; i++) {
                print(
                    "Marker $i: Lat: ${points[i].latitude}, Lng: ${points[i].longitude}");
              }
            },
            child: const Icon(Icons.directions),
          ),
          // FloatingActionButton.extended(
          //   label: Row(
          //     children: [
          //       const Text('Transformer'),
          //       Switch(
          //         activeColor: Colors.blue.shade200,
          //         activeTrackColor: Colors.black38,
          //         value: _useTransformer,
          //         onChanged: (newValue) {
          //           setState(() => _useTransformer = newValue);
          //         },
          //       ),
          //     ],
          //   ),
          //   onPressed: () {
          //     setState(() => _useTransformer = !_useTransformer);
          //   },
          // ),
        ],
      ),
    );
  }

  void _addMarker(LatLng point) {
    try {
      markers.value = List.from(markers.value)
        ..add(
          MyMarker(
            point: point,
            onTap: () => _animatedMapController.animateTo(
              dest: point,
              // customId: _useTransformer ? _useTransformerId : null,
            ),
          ),
        );
    } catch (e, stackTrace) {
      print('Error adding marker: $e\n$stackTrace');
    }
  }

  void onMarkerTap(CustomMarker marker) {
    print("Marker ${marker.name} tapped!");
  }
}

class MyMarker extends AnimatedMarker {
  MyMarker({
    required super.point,
    VoidCallback? onTap,
  }) : super(
          width: markerSize,
          height: markerSize,
          builder: (context, animation) {
            final size = markerSize * animation.value;

            return GestureDetector(
              onTap: onTap,
              child: Opacity(
                opacity: animation.value,
                child: Icon(
                  Icons.room,
                  size: size,
                ),
              ),
            );
          },
        );

  static const markerSize = 50.0;
}

class SeparatedColumn extends StatelessWidget {
  const SeparatedColumn({
    super.key,
    required this.separator,
    this.children = const [],
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final Widget separator;
  final List<Widget> children;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        ..._buildChildren(),
      ],
    );
  }

  Iterable<Widget> _buildChildren() sync* {
    for (var i = 0; i < children.length; i++) {
      yield children[i];
      if (i < children.length - 1) yield separator;
    }
  }
}

/// Inspired by the contribution of [rorystephenson](https://github.com/fleaflet/flutter_map/pull/1475/files#diff-b663bf9f32e20dbe004bd1b58a53408aa4d0c28bcc29940156beb3f34e364556)
final _animatedMoveTileUpdateTransformer = TileUpdateTransformer.fromHandlers(
  handleData: (updateEvent, sink) {
    final id = AnimationId.fromMapEvent(updateEvent.mapEvent);

    if (id == null) return sink.add(updateEvent);
    // if (id.customId != _MyHomePageState._useTransformerId) {
    //   if (id.moveId == AnimatedMoveId.started) {
    //     debugPrint('TileUpdateTransformer disabled, using default behaviour.');
    //   }
    //   return sink.add(updateEvent);
    // }

    switch (id.moveId) {
      case AnimatedMoveId.started:
        debugPrint('Loading tiles at animation destination.');
        sink.add(
          updateEvent.loadOnly(
            loadCenterOverride: id.destLocation,
            loadZoomOverride: id.destZoom,
          ),
        );
        break;
      case AnimatedMoveId.inProgress:
        // Do not prune or load during movement.
        break;
      case AnimatedMoveId.finished:
        debugPrint('Pruning tiles after animated movement.');
        sink.add(updateEvent.pruneOnly());
        break;
    }
  },
);
