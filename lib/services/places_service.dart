import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as sdk;

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

  PlacesService(this.apiKey);

  Future<List<Place>> getAutocomplete(String input) async {
    if (input.isEmpty) return [];

    try {
      // HTTP Autocomplete Implementation
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey';
      // if (kIsWeb) {
      //    url = 'https://api.allorigins.win/raw?url=' + Uri.encodeComponent(url);
      // }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => Place(
                    description: p['description'],
                    placeId: p['place_id'],
                  ))
              .toList();
        }
      }
    } catch (e) {
      print('PlacesService HTTP Error: $e');
    }
    return [];
  }

  Future<PlaceDetail?> getPlaceDetails(String placeId) async {
    return _getPlaceDetailsHttp(placeId);
  }

  Future<PlaceDetail?> _getPlaceDetailsHttp(String placeId) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,geometry&key=$apiKey';
      
      // if (kIsWeb) {
      //    url = 'https://api.allorigins.win/raw?url=' + Uri.encodeComponent(url);
      // }
      
      final response = await http.get(Uri.parse(url));

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
        }
      }
    } catch (e) {
      print('PlacesService: HTTP Fallback Error: $e');
    }
    return null;
  }
}
