import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/notification_preferences_model.dart';
import '../services/notification_service.dart';
import '../screens/settings_screen.dart';

/// Quick notification toggle widget for settings screen
class NotificationQuickSettings extends StatefulWidget {
  const NotificationQuickSettings({super.key});

  @override
  State<NotificationQuickSettings> createState() =>
      _NotificationQuickSettingsState();
}

class _NotificationQuickSettingsState extends State<NotificationQuickSettings> {
  final _notificationService = NotificationService();

  NotificationPreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _notificationService.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = prefs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (_preferences == null) return;

    setState(() {
      _preferences = _preferences!.copyWith(enabled: enabled);
    });

    try {
      final result = await _notificationService.toggleNotifications(enabled);
      if (mounted) {
        setState(() {
          _preferences = _preferences!.copyWith(enabled: result);
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _preferences = _preferences!.copyWith(enabled: !enabled);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingTile();
    }

    return Column(
      children: [
        _buildMainTile(),
        if (_preferences?.enabled == true) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildQuietHoursStatus(),
        ],
      ],
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.3),
              borderRadius: AppRadius.smBorder,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.smBorder,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.5),
                    borderRadius: AppRadius.smBorder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTile() {
    final enabled = _preferences?.enabled ?? false;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        // Reload after returning from settings
        _loadPreferences();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.border.withValues(alpha: 0.3),
                borderRadius: AppRadius.smBorder,
              ),
              child: Icon(
                enabled ? Icons.notifications_active : Icons.notifications_off,
                color: enabled ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    enabled
                        ? '${_preferences?.enabledTypesCount ?? 0} types enabled'
                        : 'Paused',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: _toggleNotifications,
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursStatus() {
    final quietHours = _preferences?.quietHours;
    if (quietHours == null || !quietHours.enabled)
      return const SizedBox.shrink();

    final isQuiet = quietHours.isCurrentlyQuiet();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isQuiet
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.05),
        borderRadius: AppRadius.smBorder,
        border: Border.all(
          color: isQuiet
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isQuiet ? Icons.bedtime : Icons.schedule,
            size: 16,
            color: isQuiet ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isQuiet
                  ? 'Quiet hours active (${quietHours.start} - ${quietHours.end})'
                  : 'Quiet hours: ${quietHours.start} - ${quietHours.end}',
              style: AppTextStyles.bodySmall.copyWith(
                color: isQuiet ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple notification badge indicator
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
