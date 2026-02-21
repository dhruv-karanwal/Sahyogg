import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_details_screen.dart';
import 'broadcast_advisory_screen.dart';
import 'update_safe_zone_screen.dart';

enum TimeFilter { live, oneHour, twentyFourHours, sevenDays }

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  TimeFilter _selectedFilter = TimeFilter.live;

  DateTime? _getFilterStartTime() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case TimeFilter.oneHour:
        return now.subtract(const Duration(hours: 1));
      case TimeFilter.twentyFourHours:
        return now.subtract(const Duration(hours: 24));
      case TimeFilter.sevenDays:
        return now.subtract(const Duration(days: 7));
      case TimeFilter.live:
        return null;
    }
  }

  Query<Map<String, dynamic>> _getFilteredQuery() {
    final startTime = _getFilterStartTime();
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('rescue_requests');
    
    if (startTime != null) {
      query = query.where('createdAt', isGreaterThan: Timestamp.fromDate(startTime));
    }
    
    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Dashboard',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Admin Decision Support',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Filter Chips
            _buildTimeFilterChips(),
            
            const SizedBox(height: 16),
            
            // Predicted Risk Level
            _buildRiskPrediction(),
            
            const SizedBox(height: 16),
            
            // KPI Cards Grid (2x2)
            _buildKPIGrid(context),
            
            const SizedBox(height: 24),
            
            // Top Risk Zones Section
            _buildTopRiskZones(),
            
            const SizedBox(height: 24),
            
            // Live SOS Feed
            _buildLiveSOSFeed(),
            
            const SizedBox(height: 24),
            
            // Smart Insights Section
            _buildSmartInsights(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(context),
            
            const SizedBox(height: 24),
            
            // Cast to Liquid Galaxy Button
            _buildCastButton(context),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Live', TimeFilter.live, Icons.circle, Colors.green),
          const SizedBox(width: 8),
          _buildFilterChip('1H', TimeFilter.oneHour, Icons.access_time, Colors.blue),
          const SizedBox(width: 8),
          _buildFilterChip('24H', TimeFilter.twentyFourHours, Icons.today, Colors.orange),
          const SizedBox(width: 8),
          _buildFilterChip('7D', TimeFilter.sevenDays, Icons.date_range, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TimeFilter filter, IconData icon, Color color) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF1C1F26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskPrediction() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        final totalSOS = snapshot.data?.docs.length ?? 0;
        
        String riskLevel;
        Color riskColor;
        IconData riskIcon;
        
        if (totalSOS < 20) {
          riskLevel = 'LOW';
          riskColor = const Color(0xFF10B981);
          riskIcon = Icons.check_circle;
        } else if (totalSOS <= 60) {
          riskLevel = 'MEDIUM';
          riskColor = const Color(0xFFF97316);
          riskIcon = Icons.warning;
        } else {
          riskLevel = 'HIGH';
          riskColor = const Color(0xFFDC2626);
          riskIcon = Icons.error;
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1F26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(riskIcon, color: riskColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Predicted Risk Level',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      riskLevel,
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedFilter == TimeFilter.live ? 'Live' : _getFilterLabel(),
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case TimeFilter.oneHour:
        return '1H';
      case TimeFilter.twentyFourHours:
        return '24H';
      case TimeFilter.sevenDays:
        return '7D';
      case TimeFilter.live:
        return 'Live';
    }
  }

  Widget _buildKPIGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildTotalSOSCard(context),
        _buildHighRiskZonesCard(context),
        _buildActiveSheltersCard(context),
        _buildBlockedRoutesCard(context),
      ],
    );
  }

  Widget _buildTotalSOSCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        final totalSOS = snapshot.data?.docs.length ?? 0;
        
        // Calculate last hour count
        int lastHourSOS = 0;
        if (snapshot.hasData && _selectedFilter == TimeFilter.live) {
          final now = DateTime.now();
          final oneHourAgo = now.subtract(const Duration(hours: 1));
          
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt != null && createdAt.toDate().isAfter(oneHourAgo)) {
              lastHourSOS++;
            }
          }
        }
        
        return _buildKPICard(
          context: context,
          title: 'Total SOS Requests',
          value: totalSOS.toString(),
          subtitle: _selectedFilter == TimeFilter.live ? 'Last Hour: +$lastHourSOS' : _getFilterLabel(),
          icon: Icons.sos,
          color: const Color(0xFFDC2626),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                  builder: (context) => AnalyticsDetailsScreen(
                    title: 'Rescue Request Trends',
                    type: 'sos',
                    disasterType: widget.disasterType,
                    selectedFilter: _selectedFilter,
                  ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighRiskZonesCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        int highRiskZones = 0;
        
        if (snapshot.hasData) {
          final Map<String, int> areaCount = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final area = data['area'] ?? 'Area Not Provided';
            areaCount[area] = (areaCount[area] ?? 0) + 1;
          }
          
          highRiskZones = areaCount.values.where((count) => count >= 10).length;
        }
        
        return _buildKPICard(
          context: context,
          title: 'High Risk Zones',
          value: highRiskZones.toString(),
          subtitle: 'Requires attention',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFEAB308),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                  builder: (context) => AnalyticsDetailsScreen(
                    title: 'High Risk Zones',
                    type: 'zones',
                    disasterType: widget.disasterType,
                    selectedFilter: _selectedFilter,
                  ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveSheltersCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('safe_zones').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('safe-zones').snapshots(),
            builder: (context, altSnapshot) {
              final activeShelters = _countActiveShelters(altSnapshot.data?.docs ?? []);
              return _buildShelterCard(context, activeShelters);
            },
          );
        }
        
        final activeShelters = _countActiveShelters(snapshot.data!.docs);
        return _buildShelterCard(context, activeShelters);
      },
    );
  }

  int _countActiveShelters(List<QueryDocumentSnapshot> docs) {
    int count = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? '';
      final isActive = data['isActive'] ?? false;
      
      if (status == 'Open' || isActive == true) {
        count++;
      }
    }
    return count;
  }

  Widget _buildShelterCard(BuildContext context, int activeShelters) {
    return _buildKPICard(
      context: context,
      title: 'Active Shelters',
      value: activeShelters.toString(),
      subtitle: 'Currently open',
      icon: Icons.home_work,
      color: const Color(0xFF10B981),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
                  builder: (context) => AnalyticsDetailsScreen(
                    title: 'Active Shelters',
                    type: 'shelters',
                    disasterType: widget.disasterType,
                  ),
        ),
      ),
    );
  }

  Widget _buildBlockedRoutesCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('routes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('floods').snapshots(),
            builder: (context, altSnapshot) {
              final blockedRoutes = _countBlockedRoutes(altSnapshot.data?.docs ?? []);
              return _buildRoutesCard(context, blockedRoutes);
            },
          );
        }
        
        final blockedRoutes = _countBlockedRoutes(snapshot.data!.docs);
        return _buildRoutesCard(context, blockedRoutes);
      },
    );
  }

  int _countBlockedRoutes(List<QueryDocumentSnapshot> docs) {
    int count = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isBlocked = data['isBlocked'] ?? false;
      
      if (isBlocked) {
        count++;
      }
    }
    return count;
  }

  Widget _buildRoutesCard(BuildContext context, int blockedRoutes) {
    return _buildKPICard(
      context: context,
      title: 'Blocked Routes',
      value: blockedRoutes.toString(),
      subtitle: 'Avoid these areas',
      icon: Icons.block,
      color: const Color(0xFFF97316),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
                  builder: (context) => AnalyticsDetailsScreen(
                    title: 'Route Status',
                    type: 'routes',
                    disasterType: widget.disasterType,
                  ),
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1F26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
              builder: (context, animatedValue, child) {
                return Text(
                  animatedValue.toInt().toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRiskZones() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final Map<String, int> areaCount = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final area = data['area'] ?? 'Area Not Provided';
          areaCount[area] = (areaCount[area] ?? 0) + 1;
        }

        final topZones = areaCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top3 = topZones.take(3).toList();

        if (top3.isEmpty) {
          return const SizedBox();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1F26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red.shade400, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Top Risk Zones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...top3.map((zone) => _buildRiskZoneItem(
                name: zone.key,
                sosCount: zone.value,
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskZoneItem({required String name, required int sosCount}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
            ),
            child: Text(
              '$sosCount SOS',
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSOSFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rescue_requests')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1F26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live SOS Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Latest 5',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildSOSFeedItem(data);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSOSFeedItem(Map<String, dynamic> data) {
    final area = data['area'] ?? 'Area Not Provided';
    final priority = data['priority'] ?? 'MEDIUM';
    final status = data['status'] ?? 'PENDING';
    final createdAt = data['createdAt'] as Timestamp?;
    
    Color priorityColor;
    switch (priority.toUpperCase()) {
      case 'HIGH':
        priorityColor = Colors.red;
        break;
      case 'LOW':
        priorityColor = Colors.yellow;
        break;
      default:
        priorityColor = Colors.orange;
    }

    Color statusColor = status == 'PENDING' ? Colors.orange : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _formatTime(createdAt),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildSmartInsights() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        final List<String> insights = [];
        
        if (snapshot.hasData) {
          final totalSOS = snapshot.data!.docs.length;
          
          if (totalSOS > 50) {
            insights.add('High SOS volume detected — $totalSOS active requests');
          }
          
          final Map<String, int> areaCount = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final area = data['area'] ?? 'Area Not Provided';
            areaCount[area] = (areaCount[area] ?? 0) + 1;
          }
          
          if (areaCount.isNotEmpty) {
            final topArea = areaCount.entries.reduce((a, b) => a.value > b.value ? a : b);
            if (topArea.value > 20) {
              insights.add('SOS surge detected in ${topArea.key}');
            }
          }
        }
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('safe_zones').snapshots(),
          builder: (context, shelterSnapshot) {
            if (shelterSnapshot.hasData) {
              final activeShelters = _countActiveShelters(shelterSnapshot.data!.docs);
              if (activeShelters < 3) {
                insights.add('Low shelter availability — attention required');
              }
            }
            
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('routes').snapshots(),
              builder: (context, routesSnapshot) {
                if (routesSnapshot.hasData) {
                  final blockedRoutes = _countBlockedRoutes(routesSnapshot.data!.docs);
                  if (blockedRoutes > 0) {
                    insights.add('$blockedRoutes route(s) flooded — rerouting needed');
                  }
                }
                
                if (insights.isEmpty) {
                  insights.add('All systems operating normally');
                  insights.add('No critical alerts at this time');
                  insights.add('Continue monitoring for updates');
                }
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1F26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber.shade400, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Smart Insights',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...insights.map((insight) => _buildInsightItem(insight)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInsightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'Broadcast Alert',
                  Icons.campaign,
                  const Color(0xFFEAB308),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BroadcastAdvisoryScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'Update Safe Zone',
                  Icons.add_location_alt,
                  const Color(0xFF10B981),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpdateSafeZoneScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildQuickActionButton(
              context,
              'Cast Hotspots to LG',
              Icons.cast,
              const Color(0xFF3B82F6),
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Casting live hotspots to Liquid Galaxy…',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF3B82F6),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCastButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Casting live hotspots to Liquid Galaxy…',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF3B82F6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF3B82F6).withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cast, size: 20),
            const SizedBox(width: 8),
            Text(
              'Cast to Liquid Galaxy',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}