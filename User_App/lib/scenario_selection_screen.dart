import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_gdg/flood_map_screen.dart'; // Import actual map screen

class ScenarioSelectionScreen extends StatelessWidget {
  const ScenarioSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey instead of pure white for depth
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar, color: Colors.blueAccent, size: 28),
            SizedBox(width: 8),
            Text(
              "SAHYOG",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Colors.black87,
                fontSize: 22,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Clean
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Select Active Disaster Scenario",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: GridView.count(
            physics: const BouncingScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.82, // Slightly adjusted for better text fitting
            children: [
              _buildScenarioCard(
                context,
                id: 'flood_kerala',
                title: "Kerala Flood '18",
                subtitle: "Loads 12 Safe Zones & Evacuation Routes",
                icon: Icons.water_drop_rounded,
                backgroundColor: Colors.blue.shade600, 
                textColor: Colors.white,
                targetLocation: const LatLng(10.1076, 76.3519), // Kerala
              ),
              _buildScenarioCard(
                context,
                id: 'cyclone_amphan',
                title: "Cyclone Amphan",
                subtitle: "Wind paths, shelters & structural damage",
                icon: Icons.cyclone_rounded,
                backgroundColor: Colors.teal.shade500, 
                textColor: Colors.white,
                targetLocation: const LatLng(22.9868, 87.8550), // West Bengal
              ),
              _buildScenarioCard(
                context,
                id: 'landslide_wayanad',
                title: "Landslide '24",
                subtitle: "Debris flow paths & high-risk terrain",
                icon: Icons.landscape_rounded,
                backgroundColor: Colors.orange.shade600, 
                textColor: Colors.white,
                targetLocation: const LatLng(11.6854, 76.1320), // Wayanad
              ),
              _buildScenarioCard(
                context,
                id: 'fire_uttarakhand',
                title: "Forest Fire",
                subtitle: "Thermal hotspots & smoke plume spread",
                icon: Icons.local_fire_department_rounded,
                backgroundColor: Colors.red.shade500, 
                textColor: Colors.white,
                targetLocation: const LatLng(30.0668, 79.0193), // Uttarakhand
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context, {
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required LatLng targetLocation,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FloodMapScreen(
              initialLocation: targetLocation,
              scenarioId: id,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24), // Smoother borders
      splashColor: Colors.white.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor, // Solid color
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 8), // Softer, deeper drop shadow
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0), // increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Translucent circle background for icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: textColor,
                    size: 32,
                  ),
                ),
                // "LIVE" status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                      SizedBox(width: 4),
                      Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ],
                  ),
                )
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: 0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: textColor.withOpacity(0.9), // Faded
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// PLACEHOLDER: USER MAP SCREEN
// --------------------------------------------------------------------------

class UserMapScreen extends StatelessWidget {
  final String scenarioId;
  final String title;

  const UserMapScreen({
    Key? key,
    required this.scenarioId,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              "Loading Map Data...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Scenario Code: $scenarioId"),
          ],
        ),
      ),
    );
  }
}
