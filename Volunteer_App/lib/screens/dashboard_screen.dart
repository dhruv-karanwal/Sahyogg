import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/volunteer_repository.dart';
import '../services/location_service.dart';
import '../services/fatigue_service.dart';
import '../services/mission_service.dart';
import '../models/volunteer_model.dart';
import '../models/mission_model.dart';
import '../widgets/dashboard_tile.dart';
import 'resource_hub_screen.dart';
import 'missions_screen.dart';
import 'map_screen.dart';
import 'emergency_screen.dart';
import 'profile_screen.dart';
import 'trust_score_screen.dart';
import 'mission_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final volunteerRepo = Provider.of<VolunteerRepository>(context);
    final locationService = Provider.of<LocationService>(context);
    final missionService = Provider.of<MissionService>(context);
    const volunteerId = 'vol_001';

    return StreamBuilder<VolunteerModel>(
      stream: volunteerRepo.getVolunteerProfile(volunteerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Profile not found'));
        }

        final volunteer = snapshot.data!;
        
        // Fatigue monitoring check - move out of build path if possible, or ensure it's lightweight
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<FatigueService>(context, listen: false).monitorDuty(
              volunteerId,
              volunteer,
              (msg) => _showFatigueDialog(context, msg),
            );
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Sahyog Volunteer',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                icon: const Icon(Icons.account_circle, size: 30, color: Color(0xFF6C9EEB)),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${volunteer.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Your contribution matters!',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      // 1. On/Off Duty
                      DashboardTile(
                        title: 'Duty Status',
                        subtitle: volunteer.isOnDuty ? 'On Duty' : 'Off Duty',
                        icon: Icons.power_settings_new,
                        gradientColors: [const Color(0xFF6C9EEB), const Color(0xFF4A90E2)],
                        onTap: () {},
                        trailing: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: volunteer.isOnDuty,
                            activeColor: Colors.white,
                            onChanged: (val) {
                              volunteerRepo.updateDutyStatus(volunteerId, val);
                              if (val) {
                                locationService.startTracking();
                              } else {
                                locationService.stopTracking();
                              }
                            },
                          ),
                        ),
                      ),
                      
                      // 2. Available Missions
                      DashboardTile(
                        title: 'Missions',
                        subtitle: 'Find Work',
                        icon: Icons.assignment_rounded,
                        gradientColors: [const Color(0xFF6FCF97), const Color(0xFF27AE60)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MissionsScreen()),
                          );
                        },
                      ),

                      // 3. Live Map
                      DashboardTile(
                        title: 'Live Map',
                        subtitle: 'Risk Areas',
                        icon: Icons.map_rounded,
                        gradientColors: [const Color(0xFFA78BFA), const Color(0xFF8B5CF6)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MapScreen()),
                          );
                        },
                      ),

                      // 4. Emergency Flare
                      DashboardTile(
                        title: 'Emergency',
                        subtitle: 'Need Help?',
                        icon: Icons.warning_amber_rounded,
                        gradientColors: [const Color(0xFFEB5757), const Color(0xFFC0392B)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EmergencyScreen()),
                          );
                        },
                      ),

                      // 5. Resource Hub
                      DashboardTile(
                        title: 'Resource Hub',
                        subtitle: 'Proximity Radar',
                        icon: Icons.hub_rounded,
                        gradientColors: [const Color(0xFFF2C94C), const Color(0xFFF2994A)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ResourceHubScreen()),
                          );
                        },
                      ),

                      // 6. Trust Score
                      DashboardTile(
                        title: 'Trust Score',
                        subtitle: '${volunteer.rating} Rating',
                        icon: Icons.star_rounded,
                        gradientColors: [const Color(0xFF56CCF2), const Color(0xFF2D9CDB)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TrustScoreScreen()),
                          );
                        },
                      ),

                      // 7. Duty Timer (Isolated Component)
                      _DutyTimerTile(
                        isOnDuty: volunteer.isOnDuty,
                        startTime: volunteer.dutyStartTime,
                      ),

                      // 8. Mission History
                      DashboardTile(
                        title: 'History',
                        subtitle: '${volunteer.totalMissions} Done',
                        icon: Icons.history_rounded,
                        gradientColors: [const Color(0xFF9B51E0), const Color(0xFF7B1FA2)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MissionHistoryScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFatigueDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Safety Alert', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }
}

class _DutyTimerTile extends StatefulWidget {
  final bool isOnDuty;
  final DateTime? startTime;

  const _DutyTimerTile({required this.isOnDuty, this.startTime});

  @override
  State<_DutyTimerTile> createState() => _DutyTimerTileState();
}

class _DutyTimerTileState extends State<_DutyTimerTile> {
  Timer? _timer;
  String _timeString = '00:00:00';

  @override
  void initState() {
    super.initState();
    if (widget.isOnDuty) _startTimer();
  }

  @override
  void didUpdateWidget(_DutyTimerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnDuty != oldWidget.isOnDuty) {
      if (widget.isOnDuty) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.startTime != null) {
        final duration = DateTime.now().difference(widget.startTime!);
        final hours = duration.inHours.toString().padLeft(2, '0');
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        setState(() => _timeString = '$hours:$minutes:$seconds');
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _timeString = '00:00:00');
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTile(
      title: 'Duty Timer',
      subtitle: widget.isOnDuty ? _timeString : 'Offline',
      icon: Icons.timer_outlined,
      gradientColors: [const Color(0xFFBDBDBD), const Color(0xFF757575)],
      onTap: () {},
    );
  }
}
