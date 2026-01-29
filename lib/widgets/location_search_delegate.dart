import 'package:flutter/material.dart';
import '../services/places_service.dart';

class LocationSearchDelegate extends SearchDelegate<Place?> {
  final PlacesService placesService;

  LocationSearchDelegate(this.placesService);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E232C),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1F25),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.grey),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(); // We handle selection in suggestions
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        color: const Color(0xFF1A1F25),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Search for a place',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<Place>>(
      future: placesService.getAutocomplete(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final places = snapshot.data ?? [];

        return Container(
          color: const Color(0xFF1A1F25),
          child: ListView.separated(
            itemCount: places.length,
            separatorBuilder: (ctx, i) => const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final place = places[index];
              return ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFF2979FF)),
                title: Text(
                  place.description,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => close(context, place),
              );
            },
          ),
        );
      },
    );
  }
}
