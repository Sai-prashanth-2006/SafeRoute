import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/nav_map.dart';
import '../widgets/speedometer.dart';
import '../widgets/speed_limit.dart';
import '../widgets/alert_banner.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/report_hazard_sheet.dart';
import 'dashboard_screen.dart';

import '../services/places_service.dart';
import '../services/directions_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/location_search_delegate.dart';
import '../widgets/location_search_delegate.dart';
import '../widgets/direction_input_widget.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Toggle for demo purposes
  bool _isHazardMode = false;
  int _selectedIndex = 0;
  
  // API Key - In production, use env variables
  static const String _apiKey = "AIzaSyAKNZEd5kxgeLYLP989DDt0x60eU3Wzx54";
  
  late final PlacesService _placesService;
  late final DirectionsService _directionsService;
  GoogleMapController? _mapController;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  @override
  // State for search/routing
  bool _showDirectionInput = false;
  StreamSubscription<Position>? _positionStream;
  PlaceDetail? _selectedDestination;
  String _currentMode = 'driving';
  bool _isNavigating = false; 
  Position? _currentPosition; 
  double _currentHeading = 0.0; 
  double _currentSpeed = 0.0; // In km/h
  double _speedLimit = 100.0; // Mock limit


  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(_apiKey);
    _directionsService = DirectionsService(_apiKey);
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _currentPosition = position;
        _currentHeading = position.heading;
        // Convert m/s to km/h, ensure non-negative. 
        // Note: Generic emulator might give 0. We can simulate speed with buttons later.
        if (position.speed > 0) {
           _currentSpeed = position.speed * 3.6; 
        }

        // Update User Marker
        setState(() {
          _markers = _markers.map((m) {
            if (m.markerId.value == 'origin') {
              return m.copyWith(
                positionParam: LatLng(position.latitude, position.longitude),
                rotationParam: _currentHeading,
              );
            }
            return m;
          }).toSet();
          
          // If marker doesn't exist (e.g. Free Drive mode), maybe we don't need to show it 
          // or we rely on the blue dot which is enabled when !navigating.
          // In Navigation mode, we definitely want the marker to move.
        });

        if (_isNavigating && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 18.0,
                tilt: 50.0,
                bearing: _currentHeading,
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    // Kept for initial permission check and one-off get
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    } 

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _handleSearch() async {
    final result = await showSearch(
      context: context,
      delegate: LocationSearchDelegate(_placesService),
    );

    if (result != null) {
      print("HomeScreen: getting details for ${result.placeId}");
      final details = await _placesService.getPlaceDetails(result.placeId);
      
      if (details == null) {
         print("HomeScreen: Details were null!");
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Failed to load place details. Please try again.'),
               backgroundColor: Colors.red,
             ),
           );
         }
         return;
      }
      print("HomeScreen: Got details ${details.name}, showing UI");

      setState(() {
        _selectedDestination = details;
        _showDirectionInput = true; // Show the input UI
         _isHazardMode = false;
      });

      _calculateRoute(details.lat, details.lng);
    }
  }

  Future<void> _calculateRoute(double destLat, double destLng, {String? mode}) async {
      final destination = LatLng(destLat, destLng);
      
      // Use current position if available, else fallback to a default (e.g. detailed default or 0,0)
      // If _currentPosition is null, we might want to wait or show error, but for now fallback.
      LatLng origin;
      if (_currentPosition != null) {
        origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      } else {
        // Fallback or retry getting location
        origin = const LatLng(12.92, 80.10); // Default to somewhere near Tambaram/India for testing if loc fails
        print("HomeScreen: Warning - Current position null, using default origin");
      }

      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            infoWindow: InfoWindow(title: _selectedDestination?.name ?? 'Destination'),
          ),
          Marker(
            markerId: const MarkerId('origin'),
            position: origin,
            infoWindow: const InfoWindow(title: 'My Location'),
            rotation: _currentHeading,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            // TODO: Replace with custom arrow icon asset if available
          ),
        };
        _polylines = {};
        _currentMode = mode ?? _currentMode;
      });

      // Animate Camera to fit bounds
      if (_mapController != null) {
         LatLngBounds bounds;
         if (origin.latitude > destination.latitude && origin.longitude > destination.longitude) {
           bounds = LatLngBounds(southwest: destination, northeast: origin);
         } else if (origin.longitude > destination.longitude) {
           bounds = LatLngBounds(southwest: LatLng(origin.latitude, destination.longitude), northeast: LatLng(destination.latitude, origin.longitude));
         } else if (origin.latitude > destination.latitude) {
           bounds = LatLngBounds(southwest: LatLng(destination.latitude, origin.longitude), northeast: LatLng(origin.latitude, destination.longitude));
         } else {
           bounds = LatLngBounds(southwest: origin, northeast: destination);
         }
         
         try {
           _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
         } catch(e) {
           print("HomeScreen: Camera bounds error $e");
         }
      }

      print('HomeScreen: Calling getDirections...');
      final directions = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        mode: _currentMode,
      );
      print('HomeScreen: getDirections returned: ${directions != null ? "Data" : "Null"}');

      if (directions != null) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF2979FF),
              width: 5,
              points: directions['polyline_points'],
            ),
          };
        });
      } else {
        // Fallback: Create a simulated straight-line route if API fails (common on Web)
        print("HomeScreen: Directions API failed/blocked. Using simulated route.");
        setState(() {
          _polylines = {
             Polyline(
              polylineId: const PolylineId('route_simulated'),
              color: const Color(0xFF2979FF).withOpacity(0.7), // Slightly transparent to indicate Issue
              width: 5,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dotted line for simulated
              points: [origin, destination],
            ),
          };
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Using simulated route (Web restriction bypassed)')),
           );
        }
      }
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _showDirectionInput = false; // Hide setup UI
       _isHazardMode = true; // Reuse hazard/nav overlay
    });
    
    // Tilt camera for 3D view
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0,
            tilt: 50.0,
            bearing: _currentHeading,
          ),
        ),
      );
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _showDirectionInput = true; // Show setup UI again
      _isHazardMode = false;
    });

    // Reset camera to overhead
     if (_currentPosition != null && _mapController != null) {
       _mapController!.animateCamera(
         CameraUpdate.newCameraPosition(
           CameraPosition(
             target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
             zoom: 14.0,
             tilt: 0.0,
             bearing: 0.0,
           ),
         ),
       );
     }
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _recenterMap() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied')));
      return;
    } 

    final position = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildNavView(context),
              const DashboardScreen(),
            ],
          ),
          
          if (!_showDirectionInput && (!_isHazardMode || _selectedIndex == 1) && !_isNavigating)
             Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: BottomNav(
                currentIndex: _selectedIndex,
                onTabChange: (index) => setState(() => _selectedIndex = index),
                onHazardTap: () {
                   showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const ReportHazardSheet(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavView(BuildContext context) {
    return Stack(
        children: [
          // 1. Map Layer (Full Screen)
           Positioned.fill(
            child: NavMap(
              markers: _markers,
              polylines: _polylines,
              onMapCreated: _onMapCreated,
              myLocationEnabled: !_isNavigating, // Hide blue dot in nav mode to use custom marker/rotation
            ),
          ),

          // 2. Main Content & Overlays
          SafeArea(
            child: Stack(
              children: [
                
                // --- Direction Input Card (Pre-Navigation) ---
              if (_showDirectionInput && _selectedDestination != null)
                Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: DirectionInputWidget(
                    destination: _selectedDestination!.name,
                    startLocation: "My Location",
                    onBack: () {
                      setState(() {
                        _showDirectionInput = false;
                        _selectedDestination = null;
                        _polylines.clear();
                      });
                    },
                    onModeChanged: (mode) {
                      print("Mode changed: $mode");
                      if (_selectedDestination != null) {
                         // Recalculate route with new mode
                         _calculateRoute(_selectedDestination!.lat, _selectedDestination!.lng, mode: mode);
                      }
                    },
                    onStartTap: _startNavigation, // Connect Start Button
                  ),
                ),
                
               // --- Exit Navigation Button ---
               if (_isNavigating)
                 Positioned(
                   bottom: 40, 
                   left: 20,
                   child: FloatingActionButton(
                     backgroundColor: Colors.red,
                     onPressed: _stopNavigation,
                     child: const Icon(Icons.close, color: Colors.white),
                   ),
                 ),
                
                // --- Top Area ---
                // --- Top Area ---
                if (!_isHazardMode && !_isNavigating)
                   Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: _handleSearch,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E232C),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.3),
                               blurRadius: 10,
                               offset: const Offset(0, 4),
                             ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.blue[400]),
                            const SizedBox(width: 12),
                            Text('Search destination', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_isHazardMode) ...[
                  // Hazard Mode Top Nav (Next Turn)
                   Positioned(
                    top: 16,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E232C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2979FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.turn_right, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                           Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NEXT TURN', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                              const Text('450m', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Settings Interaction
                  Positioned(
                    top: 16,
                    right: 20,
                    child: GestureDetector(
                        onTap: () => setState(() => _isHazardMode = !_isHazardMode), // Toggle fake hazard
                        child: CircleAvatar(
                          backgroundColor:  const Color(0xFF1E232C),
                          radius: 24,
                          child: const Icon(Icons.settings, color: Colors.white),
                        ),
                    ),
                  ),

                  // Hazard Card Big
                  // Only show if hazard mode AND speeding
                  if (_currentSpeed > _speedLimit)
                    Positioned(
                      top: 90,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                             colors: [Color(0xFFFF5252), Color(0xFFFF9100)],
                             begin: Alignment.topLeft,
                             end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5252).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.speed, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Text('URGENT HAZARD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.1),
                                children: [
                                  TextSpan(text: 'Speed Camera '),
                                  TextSpan(text: '250m\n', style: TextStyle(fontWeight: FontWeight.w800)),
                                  TextSpan(text: 'Ahead'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(height: 1, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ZONE LIMIT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text('${_speedLimit.toInt()} km/h', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('REDUCE SPEED', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                   // Speed Control Overlay (Middle)
                   Positioned(
                     top: 380, // Approx
                     left: 20,
                     right: 20,
                     child: IntrinsicHeight(
                       child: Stack(
                         children: [
                           // Main Black Box
                           Container(
                              margin: const EdgeInsets.only(right: 20), // Space for +/- buttons
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16181D),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('CURRENT SPEED', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(text: '${_currentSpeed.toInt()} ', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                            const TextSpan(text: 'KM/H', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Progress Bar
                                  Stack(
                                    children: [
                                       Container(height: 8, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(4))),
                                       Container(width: 200, height: 8, decoration: BoxDecoration(color: const Color(0xFF2979FF), borderRadius: BorderRadius.circular(4))),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('0', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      Text('LIMIT 100', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      Text('160', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                           ),
                           // Zoom/Speed Sim Buttons attached
                           Align(
                             alignment: Alignment.centerRight,
                             child: Container(
                               width: 48,
                               height: 96,
                               decoration: BoxDecoration(
                                 color: const Color(0xFF1E232C),
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(color: Colors.white.withOpacity(0.1)),
                               ),
                               child: Column(
                                 children: [
                                   Expanded(child: InkWell(
                                     onTap: () => setState(() => _currentSpeed += 5), // Sim speed up
                                     child: Icon(Icons.add, color: Colors.white.withOpacity(0.8)),
                                   )),
                                   Expanded(child: InkWell(
                                     onTap: () => setState(() => _currentSpeed = (_currentSpeed - 5).clamp(0, 200)), // Sim speed down
                                     child: Icon(Icons.remove, color: Colors.white.withOpacity(0.8)),
                                   )),
                                 ],
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),

                   // Feedback Bottom Sheet
                   Positioned(
                     bottom: 20,
                     left: 20,
                     right: 20,
                     child: Container(
                       padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16181D),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            const Text('Is the hazard still there?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2979FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        SizedBox(height: 4),
                                        Text('STILL THERE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isHazardMode = false),
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2C313A),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.cancel, color: Colors.white, size: 20),
                                          SizedBox(height: 4),
                                          Text('CLEARED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('REPORTED BY 12 DRIVERS RECENTLY', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          ],
                        ),
                     ),
                   ),

                ],

                // --- Standard Mode UI Group ---
                // We use Positioned widgets for exact coordinates observed in image 1.
                 if (!_isHazardMode) ...[
                     // Speedometer Group (Top Right relative to center)
                     // --- Right Side Controls Column ---
                     Positioned(
                       right: 16,
                       top: 140,
                       bottom: 120, // Above Bottom Nav
                       child: SingleChildScrollView( // Fix Overflow
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.center,
                           children: [
                             // Speedometer
                             Speedometer(speed: _currentSpeed.toInt()),

                             const SizedBox(height: 24),

                             // Speed Limit
                             const SpeedLimit(limit: 80),

                             const SizedBox(height: 16),

                             // Hazard (Construction) Icon
                             Container(
                                 padding: const EdgeInsets.all(10),
                                 decoration: BoxDecoration(
                                   color: const Color(0xFFFF6D00), // Orange
                                   shape: BoxShape.circle,
                                   border: Border.all(color: Colors.white, width: 2),
                                 ),
                                 child: const Icon(Icons.build, color: Colors.white, size: 20),
                               ),

                               const SizedBox(height: 20),

                               // Map Controls
                               Column(
                                 children: [
                                    GestureDetector(
                                       onTap: () => setState(() => _isHazardMode = true),
                                       child: const _MapButton(icon: Icons.warning_amber_rounded)
                                    ),
                                    const SizedBox(height: 12),
                                   const _MapButton(icon: Icons.layers_outlined),
                                 ],
                               ),
                           ],
                         ),
                       ),
                     ),

                     // Nav Arrow (Blue Box) - Vertically Centered Left
                     Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _recenterMap,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2979FF), Color(0xFF2962FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                   BoxShadow(
                                    color: const Color(0xFF2979FF).withOpacity(0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation, 
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),

                 ],
                 
              ],
            ),
          ),
        ],
      );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;

  const _MapButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E232C).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14), // Slightly more rounded
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
