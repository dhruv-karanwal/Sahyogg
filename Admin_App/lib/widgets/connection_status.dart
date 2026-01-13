import 'package:flutter/material.dart';

class ConnectionStatus extends StatelessWidget {
  final bool isConnected;
  final String label;
  final VoidCallback? onSettingsPressed;

  const ConnectionStatus({
    super.key,
    required this.isConnected,
    required this.label,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (onSettingsPressed != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 12,
              color: color.withOpacity(0.3),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onSettingsPressed,
              borderRadius: BorderRadius.circular(20),
              child: Icon(
                Icons.settings,
                size: 16,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
