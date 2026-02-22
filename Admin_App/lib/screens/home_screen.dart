import 'package:apps/screens/dashboard/dashboard_screen.dart';
import 'package:apps/screens/map_controller_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/lg_controller.dart';
import 'settings_screen.dart';
import '../widgets/custom_glass_card.dart';
import '../widgets/neu_button.dart';
import '../widgets/connection_status.dart';
import '../widgets/entry_animation.dart';
import 'send_kml_screen.dart';
import 'update_safe_zone_screen.dart';
import 'broadcast_advisory_screen.dart';
import 'rescue_requests_screen.dart';
import 'volunteer_alerts_screen.dart';

import 'shelter_list_screen.dart';

import 'package:apps/services/safe_zone_lg_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final SSHController sshController;
  final SettingsController settingsController;
  final LGController lgController;
  final String initialDisaster;

  const HomeScreen({
    super.key,
    required this.sshController,
    required this.settingsController,
    required this.lgController,
    required this.initialDisaster,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isConnected = false;
  bool _isLoading = false;
  late SafeZoneLGService _safeZoneLGService;
  late String _selectedDisaster;

  Color _getDisasterColor() {
    switch (_selectedDisaster) {
      case 'Forest Fire':
        return Colors.red;
      case 'Cyclone':
        return Colors.grey;
      case 'Landslide':
        return Colors.brown;
      case 'Flood':
      default:
        return Colors.blue;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDisaster = widget.initialDisaster;
    _safeZoneLGService = SafeZoneLGService(widget.lgController, _selectedDisaster);
    if (widget.settingsController.lgHost.isNotEmpty && 
        widget.settingsController.lgPassword.isNotEmpty) {
      _checkConnection();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.settingsController.lgHost.isEmpty || 
          widget.settingsController.lgPassword.isEmpty) {
        setState(() => _isConnected = false);
        return;
      }
      
      final success = await widget.sshController.connect(
        host: widget.settingsController.lgHost,
        port: widget.settingsController.lgPort,
        username: widget.settingsController.lgUsername,
        password: widget.settingsController.lgPassword,
      );
      
      setState(() => _isConnected = success);
      
      if (success) {
        _showSuccess('LG Connection Active');
      }
    } catch (e) {
      setState(() => _isConnected = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendLogoToLeftScreen() async {
    try {
      setState(() => _isLoading = true);
      
      await widget.lgController.sendLogoToLeftScreen(
        assetPath: 'assets/logo.png',
        logoScreenNumber: 3,
      );
      
      _showSuccess('Logo sent to left screen');
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLogoFromLeftScreen() async {
    try {
      setState(() => _isLoading = true);
      
      await widget.lgController.clearLogoFromLeftScreen(
        logoScreenNumber: 3,
      );
      
      _showSuccess('Logo cleared');
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupLiveUpdates() async {
    try {
      setState(() => _isLoading = true);
      await widget.lgController.setRefresh();
      _showSuccess('Live updates enabled (rebooting...)');
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          sshController: widget.sshController,
          settingsController: widget.settingsController,
        ),
      ),
    );

    if (result == true) {
      _checkConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView( // Allow scrolling on smaller screens
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'Command Center',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Control your Liquid Galaxy rig from here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                      _buildControlGrid(),
                      _buildMonitoringPanel(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.rocket_launch, 
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LG CONTROLLER',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getDisasterColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Active Scenario: $_selectedDisaster',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getDisasterColor(),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              _buildRiskBadge(),
              ConnectionStatus(
                isConnected: _isConnected,
                label: _isConnected ? 'CONNECTED' : 'OFFLINE',
                onSettingsPressed: _navigateToSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt grid count based on width
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        
        Color? glow;
        Color? outline;
        String mapSubtitle = '';
        String perimeterLabel = '';
        String rescueLabel = '';

        switch (_selectedDisaster) {
          case 'Forest Fire':
            glow = Colors.redAccent;
            outline = Colors.redAccent.withOpacity(0.5);
            mapSubtitle = 'Fire Spread Visualization Mode';
            perimeterLabel = 'Define Fire\nPerimeter';
            rescueLabel = 'Evacuation\nRequests';
            break;
          case 'Flood':
            glow = Colors.blueAccent;
            outline = Colors.blueAccent.withOpacity(0.5);
            mapSubtitle = 'Water Level Visualization Mode';
            perimeterLabel = 'Define Flood\nPerimeter';
            rescueLabel = 'Boat Rescue\nRequests';
            break;
          case 'Cyclone':
            glow = Colors.tealAccent;
            outline = Colors.tealAccent.withOpacity(0.5);
            mapSubtitle = 'Cyclone Path Visualization Mode';
            perimeterLabel = 'Define Cyclone\nPerimeter';
            rescueLabel = 'Airlift Supply\nRequests';
            break;
          case 'Landslide':
            glow = Colors.orangeAccent;
            outline = Colors.orangeAccent.withOpacity(0.5);
            mapSubtitle = 'Terrain Instability Visualization Mode';
            perimeterLabel = 'Define Landslide\nPerimeter';
            rescueLabel = 'Search & Rescue\nRequests';
            break;
        }
        
        final children = [
          NeuButton(
            icon: Icons.map_outlined,
            label: 'Map\nController',
            subtitle: mapSubtitle,
            color: const Color(0xFF06B6D4), // Cyan
            glowColor: glow,
            outlineColor: outline,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MapControllerScreen(
                  lgController: widget.lgController,
                  disasterType: _selectedDisaster,
                ),
              ),
            ),
          ),
          NeuButton(
            icon: Icons.layers,
            label: 'Send KML\nLayers',
            color: const Color(0xFF8B5CF6), // Violet
            glowColor: glow,
            outlineColor: outline,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SendKmlScreen(
                lgController: widget.lgController,
                disasterType: _selectedDisaster,
              )),
            ),
          ),
          NeuButton(
            icon: Icons.add_location_alt,
            label: perimeterLabel,
            color: const Color(0xFFF97316), // Orange
            glowColor: glow,
            outlineColor: outline,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UpdateSafeZoneScreen(
                  disasterType: _selectedDisaster,
                ),
              ),
            ),
          ),
          NeuButton(
            icon: Icons.visibility, // Visibility icon
            label: 'Visualise\nShelters',
            color: const Color(0xFFD946EF), // Magenta
            glowColor: glow,
            outlineColor: outline,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShelterListScreen(
                  lgController: widget.lgController,
                  disasterType: _selectedDisaster,
                ),
              ),
            ),
          ),
          NeuButton(
            icon: Icons.warning_amber_rounded,
            label: 'Broadcast\nAdvisory',
            color: const Color(0xFFEAB308), // Amber
            glowColor: glow,
            outlineColor: outline,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BroadcastAdvisoryScreen(
                  disasterType: _selectedDisaster,
                ),
              ),
            ),
          ),
          NeuButton(
            icon: Icons.sos,
            label: rescueLabel,
            color: const Color(0xFFDC2626), // Red
            glowColor: glow,
            outlineColor: outline,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RescueRequestsScreen(
                  lgController: widget.lgController,
                  disasterType: _selectedDisaster,
                ),
              ),
            ),
          ),
          NeuButton(
            icon: Icons.personal_injury,
            label: 'Volunteer\nAlerts',
            color: const Color(0xFFEF4444), // Scarlet Red
            glowColor: glow,
            outlineColor: outline,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VolunteerAlertsScreen(
                  lgController: widget.lgController,
                ),
              ),
            ),
          ),
          if (_selectedDisaster == 'Flood')
            NeuButton(
              icon: Icons.water_damage,
              label: 'Flood Prone\nRegions',
              color: const Color(0xFF3B82F6), // Blue
              glowColor: glow,
              outlineColor: outline,
              onPressed: _isConnected ? _showFloodProneRegions : null,
            ),
          if (_selectedDisaster == 'Forest Fire')
            NeuButton(
              icon: Icons.local_fire_department,
              label: 'Fire Risk\nZones',
              color: Colors.red,
              glowColor: glow,
              outlineColor: outline,
              onPressed: _isConnected ? _showFloodProneRegions : null,
            ),
          if (_selectedDisaster == 'Cyclone')
            NeuButton(
              icon: Icons.storm,
              label: 'Cyclone Prone\nRegions',
              color: Colors.grey,
              glowColor: glow,
              outlineColor: outline,
              onPressed: _isConnected ? _showFloodProneRegions : null,
            ),
          if (_selectedDisaster == 'Landslide')
            NeuButton(
              icon: Icons.landslide,
              label: 'Landslide Prone\nRegions',
              color: Colors.brown,
              glowColor: glow,
              outlineColor: outline,
              onPressed: _isConnected ? _showFloodProneRegions : null,
            ),
          NeuButton(
            icon: Icons.analytics,
            label: 'Analytics\nDashboard',
            color: const Color(0xFF10B981), // Green
            glowColor: glow,
            outlineColor: outline,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardScreen(
                  disasterType: _selectedDisaster,
                ),
              ),
            ),
          ),
          
          NeuButton(
            icon: Icons.clear_all,
            label: 'Clean KMLs\n(Reset Earth)',
            color: const Color(0xFFEC4899), // Pink
            glowColor: glow,
            outlineColor: outline,
            onPressed: _isConnected ? () => widget.lgController.clearKmls() : null,
          ),
          NeuButton(
            icon: Icons.refresh,
            label: 'Relaunch\n(Reboot LG)',
            color: const Color(0xFF06B6D4), // Cyan
            glowColor: glow,
            outlineColor: outline,
            onPressed: _isConnected ? _setupLiveUpdates : null,
          ),
          NeuButton(
            icon: Icons.settings,
            label: 'Settings\n(Configure)',
            color: Colors.grey,
            glowColor: glow,
            outlineColor: outline,
            onPressed: _navigateToSettings,
          ),
        ];

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0, 
          children: List.generate(children.length, (index) {
            return EntryAnimation(
              index: index,
              child: children[index],
            );
          }),
        );
      }
    );
  }
  Future<void> _showFloodProneRegions() async {
    try {
      setState(() => _isLoading = true);
      await widget.lgController.sendFloodProneRegionsKml();
      _showSuccess('Flood prone regions displayed on Liquid Galaxy');
    } catch (e) {
      _showError('Failed to display flood regions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRiskBadge() {
    String text;
    Color color;
    
    switch (_selectedDisaster) {
      case 'Forest Fire':
        text = 'Risk Level: Severe (Red)';
        color = Colors.redAccent;
        break;
      case 'Flood':
        text = 'Risk Level: High (Blue)';
        color = Colors.blueAccent;
        break;
      case 'Cyclone':
        text = 'Risk Level: Critical (Orange)';
        color = Colors.orangeAccent;
        break;
      case 'Landslide':
        text = 'Risk Level: Moderate (Brown)';
        color = Colors.brown;
        break;
      default:
        text = 'Risk Level: Unknown';
        color = Colors.grey;
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildMonitoringPanel() {
    final isEnabled = _isConnected; // For UI sake, you can make it glow if connected
    
    String title;
    Color color;
    List<Widget> cards;

    switch (_selectedDisaster) {
      case 'Forest Fire':
        title = 'Fire Monitoring Systems';
        color = Colors.redAccent;
        cards = [
          Expanded(child: _buildInfoCard('Active Fire Zones', '3 Detected', Icons.local_fire_department, Colors.orange, isEnabled)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Spread Prediction', 'N/NE Wind', Icons.air, Colors.redAccent, isEnabled)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Air Quality Risk', 'Hazardous', Icons.masks, Colors.purple, isEnabled)),
        ];
        break;
      case 'Flood':
        title = 'Flood Monitoring Systems';
        color = Colors.blueAccent;
        cards = [
          Expanded(child: _buildInfoCard('Water Level', '+2.4m Above', Icons.waves, Colors.blue, isEnabled)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Rainfall Forecast', 'Heavy Rain', Icons.cloudy_snowing, Colors.cyan, isEnabled)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Dam Status', '78% Capacity', Icons.water_damage, Colors.indigo, isEnabled)),
        ];
        break;
      case 'Cyclone':
        title = 'Cyclone Tracking Systems';
        color = Colors.tealAccent;
        cards = [
          Expanded(child: _buildInfoCard('Wind Speed', '165 km/h', Icons.storm, Colors.teal, isEnabled)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Eye Distance', '120 km', Icons.radar, Colors.cyanAccent, isEnabled)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Surge Warning', '2m Expected', Icons.tsunami, Colors.blueAccent, isEnabled)),
        ];
        break;
      case 'Landslide':
      default:
        title = 'Terrain Monitoring Systems';
        color = Colors.orangeAccent;
        cards = [
          Expanded(child: _buildInfoCard('Soil Moisture', '94% Saturation', Icons.water_drop, Colors.brown, isEnabled)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Seismic Activity', 'Minor Tremors', Icons.vibration, Colors.orange, isEnabled)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Road Blockages', '4 Routes', Icons.add_road, Colors.redAccent, isEnabled)),
        ];
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 16),
        Row(children: cards),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}