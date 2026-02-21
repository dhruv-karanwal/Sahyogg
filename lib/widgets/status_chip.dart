import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusChip({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        color = const Color(0xFF6FCF97);
        icon = Icons.check_circle_outline;
        break;
      case 'in_progress':
        color = const Color(0xFF6C9EEB);
        icon = Icons.sync;
        break;
      case 'assigned':
        color = const Color(0xFFF2C94C);
        icon = Icons.person_outline;
        break;
      case 'pending':
        color = const Color(0xFFA78BFA);
        icon = Icons.hourglass_empty;
        break;
      case 'on duty':
        color = const Color(0xFF6FCF97);
        icon = Icons.radio_button_checked;
        break;
      case 'off duty':
        color = const Color(0xFFEB5757);
        icon = Icons.radio_button_off;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 14 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 10 : 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
