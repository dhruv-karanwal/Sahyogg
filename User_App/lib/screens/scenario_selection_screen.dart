import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../flood_map_screen.dart';

class ScenarioSelectionScreen extends StatelessWidget {
  const ScenarioSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold background is already set via theme, but let's be explicit
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SAHYOG',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select Active Disaster Scenario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scenarios List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildScenarioCard(
                    context,
                    title: 'Kerala Flood 2018',
                    subtitle: 'Loads 12 Safe Zones & Evacuation Routes',
                    icon: Icons.water_drop,
                    accentColor: Colors.blue.shade600,
                    scenarioId: 'flood_kerala_2018',
                    disasterType: 'Flood',
                    targetLocation: const LatLng(10.1076, 76.3519), // Kerala
                  ),
                  _buildScenarioCard(
                    context,
                    title: 'Cyclone Amphan - Bengal',
                    subtitle: 'Loads 12 Safe Zones & Evacuation Routes',
                    icon: Icons.cyclone,
                    accentColor: Colors.teal.shade500,
                    scenarioId: 'cyclone_amphan_bengal',
                    disasterType: 'Cyclone',
                    targetLocation: const LatLng(22.9868, 87.8550), // West Bengal Coastline approx
                  ),
                  _buildScenarioCard(
                    context,
                    title: 'Wayanad Landslide 2024',
                    subtitle: 'Loads 12 Safe Zones & Evacuation Routes',
                    icon: Icons.landscape,
                    accentColor: Colors.brown.shade500,
                    scenarioId: 'landslide_wayanad_2024',
                    disasterType: 'Landslide',
                    targetLocation: const LatLng(11.6854, 76.1320), // Wayanad
                  ),
                  _buildScenarioCard(
                    context,
                    title: 'Uttarakhand Forest Fire',
                    subtitle: 'Loads 12 Safe Zones & Evacuation Routes',
                    icon: Icons.local_fire_department,
                    accentColor: Colors.deepOrange.shade600,
                    scenarioId: 'forest_fire_uttarakhand',
                    disasterType: 'Forest Fire',
                    targetLocation: const LatLng(30.0668, 79.0193), // Uttarakhand
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String scenarioId,
    required String disasterType,
    required LatLng targetLocation,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withOpacity(0.2),
          highlightColor: accentColor.withOpacity(0.1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FloodMapScreen(
                  targetLocation: targetLocation,
                  disasterType: disasterType,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 34,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 20),
                
                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: accentColor.withOpacity(0.8), // Arrow matching the accent
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


