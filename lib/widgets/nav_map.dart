import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NavMap extends StatelessWidget {
  const NavMap({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(40.4168, -3.7038), // Madrid
        initialZoom: 14.0,
        initialRotation: 0.0,
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.all &
              ~InteractiveFlag
                  .rotate, // Disable rotation for now to keep it simple, or enable it.
        ),
      ),
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.6, 0.0, 0.0, 0.0, 0.0, // R
            0.0, 0.6, 0.0, 0.0, 0.0, // G
            0.0, 0.0, 1.3, 0.0, 0.0, // B (Boost Blue)
            0.0, 0.0, 0.0, 1.0, 0.0, // A
          ]),
          child: TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.navpro',
          ),
        ),
        // Current Location Marker (Visual only for now)
        MarkerLayer(
          markers: [
            Marker(
              point: const LatLng(40.4168, -3.7038),
              width: 80,
              height: 80,
              child: const _CurrentLocationPuck(),
            ),
          ],
        ),
      ],
    );
  }
}

class _CurrentLocationPuck extends StatelessWidget {
  const _CurrentLocationPuck();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.5, // Slight tilt to match bearing
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2979FF).withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(20), // Pulse effect area
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2979FF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2979FF),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.navigation, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
