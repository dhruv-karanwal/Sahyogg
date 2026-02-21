import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_dashboard_screen.dart';

class AnalyticsDetailsScreen extends StatefulWidget {
  final String title;
  final String type; // 'sos', 'zones', 'shelters', 'routes'
  final TimeFilter? selectedFilter;
  final String disasterType;

  const AnalyticsDetailsScreen({
    super.key,
    required this.title,
    required this.type,
    required this.disasterType,
    this.selectedFilter,
  });

  @override
  State<AnalyticsDetailsScreen> createState() => _AnalyticsDetailsScreenState();
}

class _AnalyticsDetailsScreenState extends State<AnalyticsDetailsScreen> {
  late TimeFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter ?? TimeFilter.live;
  }

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
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.type == 'sos' || widget.type == 'zones')
              _buildTimeFilterChips(),
            if (widget.type == 'sos' || widget.type == 'zones')
              const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 24),
            _buildInsights(),
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

  Widget _buildChart() {
    switch (widget.type) {
      case 'sos':
        return _buildSOSChart();
      case 'zones':
        return _buildRiskZonesChart();
      case 'shelters':
        return _buildSheltersChart();
      case 'routes':
        return _buildRoutesChart();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSOSChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Group SOS by area for bar chart
        final Map<String, int> areaCount = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final area = data['area'] ?? 'Area Not Provided';
          areaCount[area] = (areaCount[area] ?? 0) + 1;
        }

        // Sort and take top 10
        final sortedAreas = areaCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top10 = sortedAreas.take(10).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1F26),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOS Requests by Area',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: top10.isEmpty
                    ? const Center(
                        child: Text(
                          'No SOS data available',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (top10.first.value * 1.2).toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.black87,
                              tooltipPadding: const EdgeInsets.all(8),
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${top10[group.x.toInt()].key}\n${rod.toY.toInt()} SOS',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= top10.length) return const SizedBox();
                                  final area = top10[value.toInt()].key;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      area.length > 8 ? '${area.substring(0, 8)}...' : area,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white.withOpacity(0.1),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            top10.length,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: top10[index].value.toDouble(),
                                  color: const Color(0xFFDC2626),
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskZonesChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Group SOS by area
        final Map<String, int> areaCount = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final area = data['area'] ?? 'Area Not Provided';
          areaCount[area] = (areaCount[area] ?? 0) + 1;
        }

        // Filter high risk zones (>= 10 SOS) and take top 5
        final highRiskZones = areaCount.entries
            .where((e) => e.value >= 10)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = highRiskZones.take(5).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1F26),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'High Risk Zones (≥10 SOS) - Top 5',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: top5.isEmpty
                    ? const Center(
                        child: Text(
                          'No high risk zones detected',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (top5.first.value * 1.2).toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.black87,
                              tooltipPadding: const EdgeInsets.all(8),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${top5[group.x.toInt()].key}\n${rod.toY.toInt()} SOS',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= top5.length) return const SizedBox();
                                  final area = top5[value.toInt()].key;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      area.length > 8 ? '${area.substring(0, 8)}...' : area,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white.withOpacity(0.1),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            top5.length,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: top5[index].value.toDouble(),
                                  color: const Color(0xFFEAB308),
                                  width: 30,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheltersChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Disasters')
          .doc(widget.disasterType)
          .collection('safe_zones')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Fallback to older collection if needed
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('safe-zones')
                .snapshots(),
            builder: (context, altSnapshot) {
              if (!altSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildSheltersPieChart(altSnapshot.data!.docs);
            },
          );
        }
        return _buildSheltersPieChart(snapshot.data!.docs);
      },
    );
  }

  Widget _buildSheltersPieChart(List<QueryDocumentSnapshot> docs) {
    int openCount = 0;
    int closedCount = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? '';
      final isActive = data['isActive'] ?? false;

      if (status == 'Open' || isActive == true) {
        openCount++;
      } else {
        closedCount++;
      }
    }

    final total = openCount + closedCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shelter Status Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: total == 0
                ? const Center(
                    child: Text(
                      'No shelter data available',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: [
                              PieChartSectionData(
                                value: openCount.toDouble(),
                                title: '$openCount\nOpen',
                                color: const Color(0xFF10B981),
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: closedCount.toDouble(),
                                title: '$closedCount\nClosed',
                                color: const Color(0xFF6B7280),
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Open', const Color(0xFF10B981), openCount),
                          const SizedBox(height: 12),
                          _buildLegendItem('Closed', const Color(0xFF6B7280), closedCount),
                          const SizedBox(height: 16),
                          Text(
                            'Total: $total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('routes')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Try alternate collection name
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('floods')
                .snapshots(),
            builder: (context, altSnapshot) {
              if (!altSnapshot.hasData) {
                return _buildNoRoutesData();
              }
              return _buildRoutesBarChart(altSnapshot.data!.docs);
            },
          );
        }
        return _buildRoutesBarChart(snapshot.data!.docs);
      },
    );
  }

  Widget _buildRoutesBarChart(List<QueryDocumentSnapshot> docs) {
    int blockedCount = 0;
    int unblockedCount = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isBlocked = data['isBlocked'] ?? false;

      if (isBlocked) {
        blockedCount++;
      } else {
        unblockedCount++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (blockedCount > unblockedCount ? blockedCount : unblockedCount) * 1.2,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Blocked', style: TextStyle(color: Colors.white54, fontSize: 12));
                          case 1:
                            return const Text('Clear', style: TextStyle(color: Colors.white54, fontSize: 12));
                          default:
                            return const SizedBox();
                        }
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: blockedCount.toDouble(),
                        color: const Color(0xFFF97316),
                        width: 60,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: unblockedCount.toDouble(),
                        color: const Color(0xFF10B981),
                        width: 60,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRoutesData() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'No blocked routes data',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade400, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Key Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightText('Real-time data updates automatically'),
          _buildInsightText('Tap on data points for detailed information'),
          _buildInsightText('Charts refresh when Firestore data changes'),
          if (widget.type == 'sos' || widget.type == 'zones')
            _buildInsightText('Use time filters to analyze trends'),
        ],
      ),
    );
  }

  Widget _buildInsightText(String text) {
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
}