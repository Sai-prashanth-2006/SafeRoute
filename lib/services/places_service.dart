import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as sdk;

class Place {
  final String description;
  final String placeId;

  Place({required this.description, required this.placeId});

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}

class PlaceDetail {
  final String placeId;
  final double lat;
  final double lng;
  final String name;

  PlaceDetail({
    required this.placeId,
    required this.lat,
    required this.lng,
    required this.name,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return PlaceDetail(
      placeId: json['place_id'] ?? '',
      lat: location['lat'],
      lng: location['lng'],
      name: json['name'] ?? '',
    );
  }
}



// Note: Keeping existing Place classes to avoid breaking UI, 
// but mapping from SDK response would be ideal.
// For now, we will map SDK responses to our Place class.

class PlacesService {
  final String apiKey;
  late final sdk.FlutterGooglePlacesSdk _placesSdk;

  PlacesService(this.apiKey) {
    _placesSdk = sdk.FlutterGooglePlacesSdk(apiKey);
  }

  Future<List<Place>> getAutocomplete(String input) async {
    if (input.isEmpty) return [];

    try {
      final response = await _placesSdk.findAutocompletePredictions(input);
      if (response.predictions.isNotEmpty) {
        return response.predictions
            .map((p) => Place(
                  description: p.fullText,
                  placeId: p.placeId,
                ))
            .toList();
      }
    } catch (e) {
      print('PlacesService SDK Error: $e');
    }
    return [];
  }

  Future<PlaceDetail?> getPlaceDetails(String placeId) async {
    print('PlacesService: Fetching details for $placeId');
    try {
      final response = await _placesSdk.fetchPlace(
        placeId,
        fields: [
          sdk.PlaceField.Location,
          sdk.PlaceField.Name,
          sdk.PlaceField.Address,
        ],
      );

      final place = response.place;
      if (place == null) {
        print('PlacesService: SDK returned null place');
      } else {
        print('PlacesService: SDK returned place: ${place.name}, latLng: ${place.latLng}');
      }

      if (place != null && place.latLng != null) {
        return PlaceDetail(
          placeId: place.id ?? placeId,
          lat: place.latLng!.lat,
          lng: place.latLng!.lng,
          name: place.name ?? '',
        );
      }
    } catch (e) {
      print('PlacesService: SDK Error ($e). Trying HTTP fallback...');
    }

    // Fallback: Direct HTTP request
    return _getPlaceDetailsHttp(placeId);
  }

  Future<PlaceDetail?> _getPlaceDetailsHttp(String placeId) async {
    try {
      // Note: Direct requests on Web will fail due to CORS unless generic proxies are used or the server supports it.
      // For this debugging session, we prefer Windows/Android where CORS is not an issue.
      String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,geometry&key=$apiKey';
      
      if (kIsWeb) {
         // Trying a different proxy that might not be blocked
         url = 'https://api.allorigins.win/raw?url=' + Uri.encodeComponent(url);
      }
      
      print('PlacesService: Fallback URL: $url');
      final response = await http.get(Uri.parse(url));
      print('PlacesService: HTTP Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
           final result = data['result'];
           final location = result['geometry']['location'];
           return PlaceDetail(
             placeId: placeId,
             lat: location['lat'],
             lng: location['lng'],
             name: result['name'] ?? '',
           );
        } else {
           print('PlacesService: HTTP API returned status: ${data['status']}');
        }
      }
    } catch (e) {
      print('PlacesService: HTTP Fallback Error: $e');
    }
    return null;
  }
}
