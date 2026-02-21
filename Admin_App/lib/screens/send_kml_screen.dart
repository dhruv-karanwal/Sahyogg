import 'package:flutter/material.dart';
import '../controllers/lg_controller.dart';

class SendKmlScreen extends StatefulWidget {
  final LGController lgController;
  final String disasterType;

  const SendKmlScreen({
    super.key,
    required this.lgController,
    required this.disasterType,
  });

  @override
  State<SendKmlScreen> createState() => _SendKmlScreenState();
}

class _SendKmlScreenState extends State<SendKmlScreen> {
  bool _isLoading = false;

  List<Map<String, dynamic>> get _layers {
    switch (widget.disasterType) {
      case 'Forest Fire':
        return [
          {
            'title': 'Thermal Hotspots',
            'subtitle': 'Ignition Points',
            'icon': Icons.local_fire_department,
            'path': 'assets/Forest_Fire_KMLs/Thermal_Hotspots.kml',
            'color': Colors.red
          },
          {
            'title': 'Fire Perimeter',
            'subtitle': 'Spread Area',
            'icon': Icons.fireplace,
            'path': 'assets/Forest_Fire_KMLs/Fire_Spread_Perimeter.kml',
            'color': Colors.orange
          },
          {
            'title': 'Vegetation Loss',
            'subtitle': 'Damaged Flora',
            'icon': Icons.park,
            'path': 'assets/Forest_Fire_KMLs/Vegetation_Loss.kml',
            'color': Colors.brown
          },
          {
            'title': 'Smoke Plume',
            'subtitle': 'Air Quality Impact',
            'icon': Icons.cloud,
            'path': 'assets/Forest_Fire_KMLs/Smoke_Plume_Dispersion.kml',
            'color': Colors.grey
          },
          {
            'title': 'Infrastructure',
            'subtitle': 'At-Risk Assets',
            'icon': Icons.warning_amber,
            'path': 'assets/Forest_Fire_KMLs/Infrastructure_At_Risk.kml',
            'color': Colors.yellow
          },
          {
            'title': 'Wildlife Impact',
            'subtitle': 'Habitat Loss',
            'icon': Icons.pets,
            'path': 'assets/Forest_Fire_KMLs/Wildlife_Impact.kml',
            'color': Colors.purple
          },
          {
            'title': 'Evacuation Routes',
            'subtitle': 'Safe Paths',
            'icon': Icons.directions_run,
            'path': 'assets/Forest_Fire_KMLs/Evacuation_Routes.kml',
            'color': Colors.blue
          },
          {
            'title': 'Safe Zones',
            'subtitle': 'Shelter Locations',
            'icon': Icons.health_and_safety,
            'path': 'assets/Forest_Fire_KMLs/Safe_Zones.kml',
            'color': Colors.green
          },
          {
            'title': 'Master Overlay',
            'subtitle': 'Combined View',
            'icon': Icons.layers,
            'path': 'assets/Forest_Fire_KMLs/Forest_Fire_Master_Detailed.kml',
            'color': Colors.teal
          },
        ];
      case 'Cyclone':
        return [
          {
            'title': 'Cyclone Track',
            'subtitle': 'Predicted Path',
            'icon': Icons.route,
            'path': 'assets/cyclone_kml/Cyclone_Track.kml',
            'color': Colors.red
          },
          {
            'title': 'Wind Intensity',
            'subtitle': 'Speed Zones',
            'icon': Icons.air,
            'path': 'assets/cyclone_kml/Wind_Intensity.kml',
            'color': Colors.orange
          },
          {
            'title': 'Rainfall Severity',
            'subtitle': 'Precipitation',
            'icon': Icons.water_drop,
            'path': 'assets/cyclone_kml/Rainfall_Severity.kml',
            'color': Colors.lightBlue
          },
          {
            'title': 'Infrastructure',
            'subtitle': 'Damage Assessment',
            'icon': Icons.home_repair_service,
            'path': 'assets/cyclone_kml/Infrastructure_Damage.kml',
            'color': Colors.brown
          },
          {
            'title': 'Power Grid Outage',
            'subtitle': 'Affected Lines',
            'icon': Icons.electric_bolt,
            'path': 'assets/cyclone_kml/Power_Grid_Outage.kml',
            'color': Colors.amber
          },
          {
            'title': 'Agriculture Impact',
            'subtitle': 'Crop Damage',
            'icon': Icons.agriculture,
            'path': 'assets/cyclone_kml/Agriculture_Impact.kml',
            'color': Colors.green
          },
          {
            'title': 'Evacuation Routes',
            'subtitle': 'Safe Paths',
            'icon': Icons.directions_bus,
            'path': 'assets/cyclone_kml/Evacuation_Routes.kml',
            'color': Colors.indigo
          },
          {
            'title': 'Safe Zones',
            'subtitle': 'Relief Camps',
            'icon': Icons.health_and_safety,
            'path': 'assets/cyclone_kml/Safe_Zones.kml',
            'color': Colors.teal
          },
          {
            'title': 'Master Ultra',
            'subtitle': 'Combined View',
            'icon': Icons.layers,
            'path': 'assets/cyclone_kml/Amphan_Master_Ultra_Detailed.kml',
            'color': Colors.deepPurple
          },
        ];
      case 'Landslide':
        return [
          {
            'title': 'Susceptibility',
            'subtitle': 'Risk Zones',
            'icon': Icons.warning,
            'path': 'assets/landslide kml/01_Landslide_Susceptibility_Zones.kml',
            'color': Colors.red
          },
          {
            'title': 'Landslide Scars',
            'subtitle': 'Impact Areas',
            'icon': Icons.terrain,
            'path': 'assets/landslide kml/02_Landslide_Scars.kml',
            'color': Colors.brown
          },
          {
            'title': 'Debris Flow',
            'subtitle': 'Flow Paths',
            'icon': Icons.arrow_downward,
            'path': 'assets/landslide kml/03_Debris_Flow_Paths.kml',
            'color': Colors.orange
          },
          {
            'title': 'Infrastructure Risk',
            'subtitle': 'At-Risk Assets',
            'icon': Icons.house,
            'path': 'assets/landslide kml/04_Infrastructure_at_Risk.kml',
            'color': Colors.deepOrange
          },
          {
            'title': 'Blocked Roads',
            'subtitle': 'Transport Impact',
            'icon': Icons.remove_road,
            'path': 'assets/landslide kml/05_Blocked_Damaged_Roads.kml',
            'color': Colors.grey
          },
          {
            'title': 'Relief Camps',
            'subtitle': 'Safe Zones',
            'icon': Icons.health_and_safety,
            'path': 'assets/landslide kml/06_Relief_Camps_Safe_Zones.kml',
            'color': Colors.teal
          },
          {
            'title': 'Evacuation',
            'subtitle': 'Safe Routes',
            'icon': Icons.directions_run,
            'path': 'assets/landslide kml/07_Evacuation_Routes.kml',
            'color': Colors.blue
          },
          {
            'title': 'Rainfall Data',
            'subtitle': 'Precipitation',
            'icon': Icons.cloudy_snowing,
            'path': 'assets/landslide kml/08_Rainfall_Data.kml',
            'color': Colors.lightBlue
          },
          {
            'title': 'Master Overlay',
            'subtitle': 'Combined View',
            'icon': Icons.layers,
            'path': 'assets/landslide kml/Master_Landslide.kml',
            'color': Colors.purple
          },
        ];
      case 'Flood':
      default:
        return [
          {
            'title': 'Before Flood',
            'subtitle': 'Baseline View',
            'icon': Icons.water_drop_outlined,
            'path': 'assets/flood-kml/1_kerala_before_flood.kml',
            'color': Colors.green
          },
          {
            'title': 'After Flood',
            'subtitle': 'Inundated Areas',
            'icon': Icons.flood,
            'path': 'assets/flood-kml/2_kerala_after_flood_extent.kml',
            'color': Colors.blue
          },
          {
            'title': 'Rainfall Severity',
            'subtitle': 'Precipitation Zones',
            'icon': Icons.cloudy_snowing,
            'path': 'assets/flood-kml/3_kerala_rainfall_severity.kml',
            'color': Colors.indigo
          },
          {
            'title': 'Basin Impact',
            'subtitle': 'River Analysis',
            'icon': Icons.landscape,
            'path': 'assets/flood-kml/4_kerala_river_basin_impact.kml',
            'color': Colors.cyan
          },
          {
            'title': 'Household Impact',
            'subtitle': 'Affected Areas',
            'icon': Icons.house,
            'path': 'assets/flood-kml/5_kerala_household_impact.kml',
            'color': Colors.orange
          },
          {
            'title': 'Vegetation Damage',
            'subtitle': 'Crop Impact',
            'icon': Icons.grass,
            'path': 'assets/flood-kml/6_kerala_vegetation_agriculture_loss.kml',
            'color': Colors.lightGreen
          },
          {
            'title': 'Urban Hotspots',
            'subtitle': 'Critical Zones',
            'icon': Icons.apartment,
            'path': 'assets/flood-kml/7_kerala_urban_flood_hotspots.kml',
            'color': Colors.red
          },
          {
            'title': 'Safe Zones',
            'subtitle': 'Relief Camps',
            'icon': Icons.health_and_safety,
            'path': 'assets/flood-kml/8_kerala_safe_zones_relief.kml',
            'color': Colors.teal
          },
          {
            'title': 'Disaster Tour',
            'subtitle': 'Tour Path',
            'icon': Icons.tour,
            'path': 'assets/flood-kml/9_kerala_disaster_tour.kml',
            'color': Colors.deepPurple
          },
        ];
    }
  }

  Future<void> _sendLayer(Map<String, dynamic> layer) async {
    setState(() => _isLoading = true);
    try {
      double lat = 10.1;
      double lng = 76.4;
      double range = 500000;
      double tilt = 45;
      
      switch (widget.disasterType) {
        case 'Forest Fire':
          lat = 30.0668; lng = 79.0193; range = 400000; break; // Uttarakhand
        case 'Cyclone':
          lat = 22.9868; lng = 87.8550; range = 900000; break; // Bengal Coast
        case 'Landslide':
          lat = 11.6050; lng = 76.0836; range = 200000; tilt = 60; break; // Wayanad Kerala
        case 'Flood':
        default:
          lat = 10.1632; lng = 76.6413; range = 800000; break; // Kerala Floods 
      }

      await widget.lgController.sendDisasterLayer(
        assetPath: layer['path'],
        lookAtLat: lat,
        lookAtLng: lng,
        lookAtRange: range,
        lookAtTilt: tilt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Layer sent: ${layer['title']}'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send layer: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Disaster Layers'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns for visibility
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _layers.length,
                  itemBuilder: (context, index) {
                    final layer = _layers[index];
                    return _buildLayerCard(layer);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildLayerCard(Map<String, dynamic> layer) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendLayer(layer),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (layer['color'] as Color).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  layer['icon'],
                  color: layer['color'],
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                layer['title'],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                layer['subtitle'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
