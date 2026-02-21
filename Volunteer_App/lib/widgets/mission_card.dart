import 'package:flutter/material.dart';
import '../widgets/status_chip.dart';

class MissionCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;
  final String? distance;

  final Widget? trailing;

  const MissionCard({
    super.key,
    required this.request,
    required this.onTap,
    this.distance,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final score = (request['score'] ?? 50.0) as double;
    final title = (request['uniqueTitle'] ?? 'Rescue Mission').toString();
    
    // Priority Colors based on Score
    Color bgColor;
    Color priorityColor;
    String priorityLabel;
    
    if (score >= 80) {
      bgColor = const Color(0xFFFFEBEE); // Pastel Red
      priorityColor = Colors.red;
      priorityLabel = 'CRITICAL';
    } else if (score >= 60) {
      bgColor = const Color(0xFFFFF3E0); // Pastel Orange
      priorityColor = Colors.orange;
      priorityLabel = 'HIGH';
    } else if (score >= 40) {
      bgColor = const Color(0xFFFFFDE7); // Pastel Yellow
      priorityColor = Colors.amber;
      priorityLabel = 'MODERATE';
    } else {
      bgColor = Colors.grey.shade100;
      priorityColor = Colors.grey;
      priorityLabel = 'LOW';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      color: bgColor,
      shadowColor: priorityColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: priorityColor.withOpacity(0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Urgency Score: ${score.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: priorityColor.darken(0.3),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: priorityColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      priorityLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: priorityColor),
                            const SizedBox(width: 6),
                            Text(
                              request['areaName'] ?? 'Unknown Location',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (distance != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.directions_walk, size: 18, color: Colors.blueGrey),
                              const SizedBox(width: 6),
                              Text(
                                distance!,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: (List<String>.from(request['requiredSkills'] ?? []))
                              .map((skill) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: priorityColor.withOpacity(0.1)),
                                    ),
                                    child: Text(
                                      skill, 
                                      style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.w900,
                                        color: priorityColor.darken(0.4),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
