import 'package:flutter/material.dart';

class DirectionInputWidget extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onModeChanged;
  final String startLocation;
  final String destination;
  final VoidCallback onStartTap;

  const DirectionInputWidget({
    super.key,
    required this.onBack,
    required this.onModeChanged,
    this.startLocation = "Your location",
    required this.destination,
    required this.onStartTap,
  });

  @override
  State<DirectionInputWidget> createState() => _DirectionInputWidgetState();
}

class _DirectionInputWidgetState extends State<DirectionInputWidget> {
  int _selectedModeIndex = 1; // Driving

  // Icons matching Google Maps
  final List<Map<String, dynamic>> _modes = [
    {'icon': Icons.assistant_navigation, 'mode': 'driving', 'label': 'Best'}, // Simulated Best
    {'icon': Icons.directions_car, 'mode': 'driving', 'label': 'Car'},
    {'icon': Icons.two_wheeler, 'mode': 'driving', 'label': 'Moto'}, // Moto sim
    {'icon': Icons.directions_bus, 'mode': 'transit', 'label': 'Transit'},
    {'icon': Icons.directions_walk, 'mode': 'walking', 'label': 'Walk'},
    {'icon': Icons.directions_bike, 'mode': 'bicycling', 'label': 'Bike'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             // --- Top Row: Travel Modes ---
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: _modes.asMap().entries.map((entry) {
                   int idx = entry.key;
                   Map mode = entry.value;
                   bool isSelected = _selectedModeIndex == idx;
                   return GestureDetector(
                     onTap: () {
                       setState(() => _selectedModeIndex = idx);
                       widget.onModeChanged(mode['mode']);
                     },
                     child: AnimatedContainer(
                       duration: const Duration(milliseconds: 200),
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       decoration: BoxDecoration(
                         color: isSelected ? const Color(0xFF2979FF).withOpacity(0.2) : Colors.transparent,
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Icon(
                         mode['icon'],
                         color: isSelected ? const Color(0xFF2979FF) : Colors.grey,
                         size: 24,
                       ),
                     ),
                   );
                 }).toList(),
               ),
             ),

             const Divider(height: 1, color: Colors.white10),

             // --- Inputs Section with Connector ---
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Back Button
                   GestureDetector(
                     onTap: widget.onBack,
                     child: const Padding(
                       padding: EdgeInsets.only(top: 8, right: 12),
                       child: Icon(Icons.arrow_back, color: Colors.white),
                     ),
                   ),

                   // Connector Visuals
                   Padding(
                     padding: const EdgeInsets.only(top: 12),
                     child: Column(
                       children: [
                         const Icon(Icons.my_location, size: 16, color: Colors.blue),
                         Container(
                           height: 30,
                           width: 2,
                           margin: const EdgeInsets.symmetric(vertical: 4),
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [Colors.blue.withOpacity(0.5), Colors.red.withOpacity(0.5)],
                               begin: Alignment.topCenter,
                               end: Alignment.bottomCenter,
                             ),
                           ),
                         ),
                         const Icon(Icons.location_on, size: 16, color: Colors.red),
                       ],
                     ),
                   ),
                   
                   const SizedBox(width: 12),

                   // Input Fields
                   Expanded(
                     child: Column(
                       children: [
                         _buildBox(widget.startLocation, true),
                         const SizedBox(height: 12),
                         _buildBox(widget.destination, false),
                       ],
                     ),
                   ),

                   const SizedBox(width: 12),
                   
                   // Swap Icon
                   const Padding(
                     padding: EdgeInsets.only(top: 30),
                     child: Icon(Icons.swap_vert, color: Colors.grey),
                   ),
                 ],
               ),
             ),


              const Divider(height: 1, color: Colors.white10),

              // --- Start Button ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                   width: double.infinity,
                   height: 50,
                   child: ElevatedButton.icon(
                     onPressed: widget.onStartTap,
                     icon: const Icon(Icons.navigation, color: Colors.white),
                     label: const Text("Start", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF2979FF),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       elevation: 4,
                     ),
                   ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildBox(String text, bool isOrigin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C313A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
