import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavMap extends StatefulWidget {
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final Function(GoogleMapController)? onMapCreated;
  final bool myLocationEnabled;

  const NavMap({
    super.key, 
    this.markers, 
    this.polylines,
    this.onMapCreated,
    this.myLocationEnabled = true,
  });

  @override
  State<NavMap> createState() => _NavMapState();
}

class _NavMapState extends State<NavMap> {
  // Madrid, Spain
  static const LatLng _initialPosition = LatLng(40.4168, -3.7038);
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _initialPosition,
        zoom: 14.0,
      ),
      markers: widget.markers ?? {},
      polylines: widget.polylines ?? {},
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
        _loadMapStyle();
      },
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
    );
  }

  Future<void> _loadMapStyle() async {
    try {
      String style = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
      _mapController?.setMapStyle(style);
    } catch (e) {
      debugPrint("Failed to load map style: $e");
    }
  }
}
