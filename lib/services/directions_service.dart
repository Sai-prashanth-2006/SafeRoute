import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    if (kIsWeb) {
       url = 'https://api.allorigins.win/raw?url=' + Uri.encodeComponent(url);
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if ((data['routes'] as List).isEmpty) return null;

      final route = data['routes'][0];
      final leg = route['legs'][0];
      final overviewPolyline = route['overview_polyline']['points'];

      // Decode polyline manually
      List<LatLng> routePoints = _decodePolyline(overviewPolyline);

      return {
        'polyline_points': routePoints,
        'distance': leg['distance']['text'],
        'duration': leg['duration']['text'],
      };
    }
    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 100000.0, lng / 100000.0));
    }
    return poly;
  }
}
