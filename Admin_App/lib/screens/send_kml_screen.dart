import 'package:flutter/material.dart';
import '../controllers/lg_controller.dart';

class SendKmlScreen extends StatefulWidget {
  final LGController lgController;

  const SendKmlScreen({super.key, required this.lgController});

  @override
  State<SendKmlScreen> createState() => _SendKmlScreenState();
}

class _SendKmlScreenState extends State<SendKmlScreen> {
  bool _isLoading = false;

  final List<Map<String, dynamic>> _layers = [
    {
      'title': 'Before Flood',
      'subtitle': 'Baseline View',
      'icon': Icons.water_drop_outlined,
      'path': 'assets/test 2/1_kerala_before_flood.kml',
      'color': Colors.green
    },
    {
      'title': 'After Flood',
      'subtitle': 'Inundated Areas',
      'icon': Icons.flood,
      'path': 'assets/test 2/2_kerala_after_flood_extent.kml',
      'color': Colors.blue
    },
    {
      'title': 'Rainfall Severity',
      'subtitle': 'Precipitation Zones',
      'icon': Icons.cloudy_snowing,
      'path': 'assets/test 2/3_kerala_rainfall_severity.kml',
      'color': Colors.indigo
    },
    {
      'title': 'Vegetation Damage',
      'subtitle': 'Crop Impact',
      'icon': Icons.grass,
      'path': 'assets/test 2/6_kerala_vegetation_agriculture_loss.kml',
      'color': Colors.lightGreen
    },
    {
      'title': 'Household Impact',
      'subtitle': 'Affected Areas',
      'icon': Icons.house,
      'path': 'assets/test 2/5_kerala_household_impact.kml',
      'color': Colors.orange
    },
    {
      'title': 'Urban Hotspots',
      'subtitle': 'Critical Zones',
      'icon': Icons.apartment,
      'path': 'assets/test 2/7_kerala_urban_flood_hotspots.kml',
      'color': Colors.red
    },
    {
      'title': 'Safe Zones',
      'subtitle': 'Relief Camps',
      'icon': Icons.health_and_safety,
      'path': 'assets/test 2/8_kerala_safe_zones_relief.kml',
      'color': Colors.teal
    },
    {
      'title': 'Basin Impact',
      'subtitle': 'River Analysis',
      'icon': Icons.landscape,
      'path': 'assets/test 2/4_kerala_river_basin_impact.kml',
      'color': Colors.cyan
    },
    {
      'title': 'Start Tour',
      'subtitle': 'Disaster Overview',
      'icon': Icons.movie_filter,
      'path': 'assets/test 2/9_kerala_disaster_tour.kml',
      'color': Colors.purple
    },
  ];

  Future<void> _sendLayer(String path, String name) async {
    setState(() => _isLoading = true);
    try {
      await widget.lgController.sendDisasterLayer(assetPath: path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Layer sent: $name'),
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
        onTap: () => _sendLayer(layer['path'], layer['title']),
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
