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

class HomeScreen extends ConsumerStatefulWidget {
  final SSHController sshController;
  final SettingsController settingsController;
  final LGController lgController;

  const HomeScreen({
    super.key,
    required this.sshController,
    required this.settingsController,
    required this.lgController,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.settingsController.lgHost.isNotEmpty && 
        widget.settingsController.lgPassword.isNotEmpty) {
      _checkConnection();
    }
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.rocket_launch, 
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LG CONTROLLER',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ConnectionStatus(
            isConnected: _isConnected,
            label: _isConnected ? 'CONNECTED' : 'OFFLINE',
            onSettingsPressed: _navigateToSettings,
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
        
        final children = [
          NeuButton(
            icon: Icons.image,
            label: 'Send Logo\n(Left Screen)',
            color: const Color(0xFF3B82F6), // Blue
            onPressed: _isConnected ? _sendLogoToLeftScreen : null,
          ),
          NeuButton(
            icon: Icons.layers,
            label: 'Send KML\nLayers',
            color: const Color(0xFF8B5CF6), // Violet
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SendKmlScreen(lgController: widget.lgController)),
            ),
          ),
          NeuButton(
            icon: Icons.add_location_alt,
            label: 'Update\nSafe Zone',
            color: const Color(0xFFF97316), // Orange
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpdateSafeZoneScreen()),
            ),
          ),
          NeuButton(
            icon: Icons.warning_amber_rounded,
            label: 'Broadcast\nAdvisory',
            color: const Color(0xFFEAB308), // Amber
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BroadcastAdvisoryScreen()),
            ),
          ),
          NeuButton(
            icon: Icons.sos,
            label: 'Rescue\nRequests',
            color: const Color(0xFFDC2626), // Red
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RescueRequestsScreen(lgController: widget.lgController)),
            ),
          ),
          NeuButton(
            icon: Icons.hide_image,
            label: 'Clear Logo\n(Left Screen)',
            color: const Color(0xFF8B5CF6), // Violet
            onPressed: _isConnected ? _clearLogoFromLeftScreen : null,
          ),

          NeuButton(
            icon: Icons.cleaning_services,
            label: 'Clean Logos\n(All Screens)',
            color: const Color(0xFFEF4444), // Red
            onPressed: _isConnected ? () => widget.lgController.clearLogos() : null,
          ),
          NeuButton(
            icon: Icons.clear_all,
            label: 'Clean KMLs\n(Reset Earth)',
            color: const Color(0xFFEC4899), // Pink
            onPressed: _isConnected ? () => widget.lgController.clearKmls() : null,
          ),
          NeuButton(
            icon: Icons.refresh,
            label: 'Relaunch\n(Reboot LG)',
            color: const Color(0xFF06B6D4), // Cyan
            onPressed: _isConnected ? _setupLiveUpdates : null,
          ),
          NeuButton(
            icon: Icons.settings,
            label: 'Settings\n(Configure)',
            color: Colors.grey,
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
}
