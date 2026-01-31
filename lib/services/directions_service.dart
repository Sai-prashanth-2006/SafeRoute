import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DirectionsService {
  final String apiKey;

  DirectionsService(this.apiKey);

  Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving', // driving, bicycling, transit, walking
  }) async {
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$mode&key=$apiKey';

    // Note: Direct requests on Web will likely fail due to CORS.
    // Use a backend proxy in production or test on Windows/Android.
    // if (kIsWeb) {
    //    url = 'https://api.allorigins.win/raw?url=' + Uri.encodeComponent(url);
    // }

    print('DirectionsService: Fetching URL: $url');
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['routes'] as List).isEmpty) {
          print('DirectionsService Warning: No routes found. Response: $data');
          return null;
        }

        final route = data['routes'][0];
        final leg = route['legs'][0];
        final overviewPolyline = route['overview_polyline']['points'];
        // Decode polyline using package (Static method)
        print('DirectionsService: Decoding Polyline (len=${overviewPolyline.length}): $overviewPolyline');
        List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(overviewPolyline);
        print('DirectionsService: Decoded ${decodedPoints.length} points using package.');

        List<LatLng> routePoints = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        return {
          'polyline_points': routePoints,
          'distance': leg['distance']['text'],
          'duration': leg['duration']['text'],
        };
      } else {
        print('DirectionsService Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DirectionsService Exception: $e');
    }
    return null;
  }
// Removed manual _decodePolyline method
}
