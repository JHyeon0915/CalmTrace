import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/ai_coach_service.dart';

class QuickChoices extends StatelessWidget {
  final List<QuickResponse> quickResponses;
  final Function(QuickResponse) onChoiceSelected;

  const QuickChoices({
    super.key,
    required this.quickResponses,
    required this.onChoiceSelected,
  });

  static const _icons = {
    'breathing': Icons.air,
    'grounding': Icons.local_florist,
    'talk': Icons.chat_bubble_outline,
    'stressed': Icons.favorite_outline,
  };

  static const _colors = {
    'breathing': Color(0xFF6B9BD1),
    'grounding': Color(0xFF8FB996),
    'talk': Color(0xFFB4A7D6),
    'stressed': Color(0xFFE89B9B),
  };

  List<QuickResponse> get _choices => quickResponses.isNotEmpty
      ? quickResponses
      : [
          QuickResponse(
            id: 'breathing',
            label: 'Breathing Exercise',
            message: "I'd like to try a breathing exercise",
          ),
          QuickResponse(
            id: 'grounding',
            label: 'Grounding Technique',
            message: 'Can you guide me through a grounding technique?',
          ),
          QuickResponse(
            id: 'talk',
            label: 'Just Talk',
            message: 'I just need someone to talk to',
          ),
        ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Choose what you'd like to explore:",
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._choices.map(
          (choice) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ChoiceButton(
              choice: choice,
              icon: _icons[choice.id] ?? Icons.arrow_forward,
              color: _colors[choice.id] ?? const Color(0xFF6B9BD1),
              onTap: () => onChoiceSelected(choice),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final QuickResponse choice;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.choice,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.lgBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBorder,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  choice.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
