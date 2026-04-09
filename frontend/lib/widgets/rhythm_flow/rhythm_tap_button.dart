import 'package:flutter/material.dart';
import '../../screens/rhythm_flow_screen.dart';

class RhythmTapButton extends StatelessWidget {
  final RhythmButton button;
  final bool isActive;
  final Animation<double> pulseAnimation;
  final RhythmStressLevel stressLevel;
  final VoidCallback onTap;

  const RhythmTapButton({
    super.key,
    required this.button,
    required this.isActive,
    required this.pulseAnimation,
    required this.stressLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          final scale = isActive ? pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: button.color.withValues(alpha: isActive ? 1.0 : 0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: button.color.withValues(
                      alpha: isActive ? 0.5 : 0.2,
                    ),
                    blurRadius: isActive ? 20 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      button.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isActive && stressLevel == RhythmStressLevel.high) ...[
                      const SizedBox(height: 4),
                      Text(
                        '2×',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
