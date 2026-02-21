import 'package:flutter/material.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/lg_controller.dart';
import '../widgets/custom_glass_card.dart';
import '../widgets/entry_animation.dart';
import 'home_screen.dart';

class ScenarioSelectionScreen extends StatelessWidget {
  final SSHController sshController;
  final SettingsController settingsController;
  final LGController lgController;

  const ScenarioSelectionScreen({
    super.key,
    required this.sshController,
    required this.settingsController,
    required this.lgController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B111B),
              Color(0xFF141A26),
              Color(0xFF0B111B),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background glow effect
            Positioned(
              top: -150,
              right: -50,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.02),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 100,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    EntryAnimation(
                      index: 0,
                      child: Row(
                        children: [
                          Icon(Icons.rocket_launch, color: Theme.of(context).colorScheme.primary, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'SAHYOG SYSTEM',
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: Colors.white,
                                  ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    EntryAnimation(
                      index: 1,
                      child: Text(
                        'INITIALIZE COMMAND CENTER',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    EntryAnimation(
                      index: 2,
                      child: Text(
                        'Please select the active disaster scenario to configure the analytics, widgets, and geographic visualizers.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white60,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 64),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2.5 : 2.0,
                        children: [
                          EntryAnimation(
                            index: 3, 
                            child: _buildScenarioCard(context, 'Flood', Icons.water_damage, Colors.blue, 'Hydrological')
                          ),
                          EntryAnimation(
                            index: 4, 
                            child: _buildScenarioCard(context, 'Forest Fire', Icons.local_fire_department, Colors.redAccent, 'Climatological')
                          ),
                          EntryAnimation(
                            index: 5, 
                            child: _buildScenarioCard(context, 'Cyclone', Icons.storm, Colors.tealAccent, 'Meteorological')
                          ),
                          EntryAnimation(
                            index: 6, 
                            child: _buildScenarioCard(context, 'Landslide', Icons.landslide, Colors.orangeAccent, 'Geophysical')
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard(BuildContext context, String title, IconData icon, Color color, String subtitle) {
    return CustomGlassCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
              sshController: sshController,
              settingsController: settingsController,
              lgController: lgController,
              initialDisaster: title,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Stack(
        children: [
          // Background subtle icon
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              icon,
              size: 160,
              color: color.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          subtitle.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54, size: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
