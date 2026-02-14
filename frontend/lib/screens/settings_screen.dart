import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/device_feedback_service.dart';
import '../services/notification_service.dart';
import '../models/notification_preferences_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _feedbackService = DeviceFeedbackService();
  final _notificationService = NotificationService();

  // Device Feedback
  DeviceFeedbackType _selectedFeedback = DeviceFeedbackType.vibration;

  // Default notification Preferences
  bool _notificationsEnabled = false;
  int _frequency = 20;
  bool _isUnlimited = false;
  bool _quietHoursEnabled = false;
  String _quietStart = "22:00";
  String _quietEnd = "08:00";

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Load device feedback setting
      final feedbackType = await _feedbackService.getFeedbackType();

      // Load notification preferences
      final notifPrefs = await _notificationService.getPreferences();

      if (mounted) {
        setState(() {
          _selectedFeedback = feedbackType;
          _notificationsEnabled = notifPrefs.enabled;
          _isUnlimited =
              notifPrefs.maxPerDay == "unlimited" ||
              notifPrefs.maxPerDay == null;
          // Only update _frequency if it's an actual number
          if (!_isUnlimited && notifPrefs.maxPerDay is int) {
            _frequency = notifPrefs.maxPerDay;
          }
          _quietHoursEnabled = notifPrefs.quietHours.enabled;
          _quietStart = notifPrefs.quietHours.start;
          _quietEnd = notifPrefs.quietHours.end;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateNotificationPreferences() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _notificationService.updatePreferences(
        enabled: _notificationsEnabled,
        maxPerDay: _isUnlimited ? "unlimited" : _frequency,
        quietHours: QuietHours(
          enabled: _quietHoursEnabled,
          start: _quietStart,
          end: _quietEnd,
        ),
      );
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _onFeedbackOptionTap(DeviceFeedbackType type) async {
    if (type == _selectedFeedback) return;

    final confirmed = await _showFeedbackConfirmDialog(type);

    if (confirmed == true) {
      await _feedbackService.setFeedbackType(type);
      if (mounted) {
        setState(() => _selectedFeedback = type);
        _showSuccessSnackBar('Device feedback changed to ${type.title}');
      }
    }
  }

  Future<void> _showTimePicker(bool isStart) async {
    final currentTime = isStart
        ? _parseTime(_quietStart)
        : _parseTime(_quietEnd);

    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = _formatTime(picked);
      setState(() {
        if (isStart) {
          _quietStart = formattedTime;
        } else {
          _quietEnd = formattedTime;
        }
      });
      _updateNotificationPreferences();
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<bool?> _showFeedbackConfirmDialog(DeviceFeedbackType type) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppRadius.smBorder,
              ),
              child: Icon(type.icon, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(type.title, style: AppTextStyles.h4),
          ],
        ),
        content: Text(
          type.confirmationMessage,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showConfirmDialog(
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmText: 'Log Out',
      isDestructive: false,
    );

    if (shouldLogout == true) {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final shouldDelete = await _showConfirmDialog(
      title: 'Delete Account',
      message:
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
      confirmText: 'Delete Account',
      isDestructive: true,
    );

    if (shouldDelete != true) return;

    final confirmDelete = await _showConfirmDialog(
      title: 'Final Confirmation',
      message:
          'This is your last chance to keep your data. Delete your account permanently?',
      confirmText: 'Yes, Delete',
      isDestructive: true,
    );

    if (confirmDelete != true) return;

    final result = await _authService.deleteAccount();

    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showErrorSnackBar(result.errorMessage ?? 'Failed to delete account');
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(title, style: AppTextStyles.h4),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: isDestructive ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: AppTextStyles.h4),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Notifications Section Header
                  _buildSectionHeader('Notifications'),
                  const SizedBox(height: AppSpacing.sm),

                  // Gentle Reminders Card
                  _buildGentleRemindersSection(),
                  const SizedBox(height: AppSpacing.md),

                  // Quiet Hours Card (only when notifications enabled)
                  if (_notificationsEnabled) ...[
                    _buildQuietHoursSection(),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Device Feedback Section
                  _buildDeviceFeedbackSection(),

                  const SizedBox(height: AppSpacing.xl),

                  // Account Section
                  _buildSectionHeader('Account'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAccountSection(),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGentleRemindersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B9BD1).withValues(alpha: 0.15),
                  borderRadius: AppRadius.smBorder,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF6B9BD1),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gentle Reminders',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prompts to check in and practice self-care',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _updateNotificationPreferences();
                },
                trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  return Colors.transparent;
                }),
                activeColor: const Color(0xFF6B9BD1),
                inactiveTrackColor: AppColors.surfaceGray,
                inactiveThumbColor: AppColors.background,
              ),
            ],
          ),

          // Frequency section (only when enabled)
          if (_notificationsEnabled) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.lg),
            _buildFrequencySection(),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with value
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Frequency',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _isUnlimited ? 'Unlimited' : '$_frequency per day',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF6B9BD1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF6B9BD1),
            inactiveTrackColor: AppColors.border,
            thumbColor: const Color(0xFF6B9BD1),
            overlayColor: const Color(0xFF6B9BD1).withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _isUnlimited ? 20 : _frequency.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: _isUnlimited
                ? null
                : (value) {
                    setState(() => _frequency = value.round());
                  },
            onChangeEnd: (_) => _updateNotificationPreferences(),
          ),
        ),

        // Scale labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              Text(
                '10',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              Text(
                '20',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Unlimited toggle button
        GestureDetector(
          onTap: () {
            setState(() => _isUnlimited = !_isUnlimited);
            _updateNotificationPreferences();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: _isUnlimited ? const Color(0xFF6B9BD1) : AppColors.surface,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: _isUnlimited
                    ? const Color(0xFF6B9BD1)
                    : AppColors.border,
              ),
            ),
            child: Text(
              _isUnlimited ? '✓ Unlimited (as needed)' : 'Set to Unlimited',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _isUnlimited ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuietHoursSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFB4A7D6).withValues(alpha: 0.2),
                  borderRadius: AppRadius.smBorder,
                ),
                child: const Icon(
                  Icons.bedtime_outlined,
                  color: Color(0xFFB4A7D6),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiet Hours',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No notifications during these times',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _quietHoursEnabled,
                onChanged: (value) {
                  setState(() => _quietHoursEnabled = value);
                  _updateNotificationPreferences();
                },
                trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  return Colors.transparent;
                }),
                activeColor: const Color(0xFFB4A7D6),
                inactiveTrackColor: AppColors.surfaceGray,
                inactiveThumbColor: AppColors.background,
              ),
            ],
          ),

          // Time pickers (only when enabled)
          if (_quietHoursEnabled) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInput(
                    label: 'Start',
                    value: _quietStart,
                    onTap: () => _showTimePicker(true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTimeInput(
                    label: 'End',
                    value: _quietEnd,
                    onTap: () => _showTimePicker(false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInput({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceFeedbackSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.textGreen.withValues(alpha: 0.2),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Icon(
                  Icons.smartphone_outlined,
                  color: AppColors.textGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Feedback',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'When Emotiv headset or smartwatch is connected',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Feedback Options Grid
          _buildFeedbackOptionsGrid(),
        ],
      ),
    );
  }

  Widget _buildFeedbackOptionsGrid() {
    return Column(
      children: [
        // First row: Vibration & Ring
        Row(
          children: [
            Expanded(child: _buildFeedbackOption(DeviceFeedbackType.vibration)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildFeedbackOption(DeviceFeedbackType.ring)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Second row: Notification & None
        Row(
          children: [
            Expanded(
              child: _buildFeedbackOption(DeviceFeedbackType.notification),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildFeedbackOption(DeviceFeedbackType.none)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackOption(DeviceFeedbackType type) {
    final isSelected = _selectedFeedback == type;

    return GestureDetector(
      onTap: () => _onFeedbackOptionTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textGreen.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(
            color: isSelected ? AppColors.textGreen : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.textGreen.withValues(alpha: 0.2)
                    : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                type.icon,
                color: isSelected
                    ? AppColors.textGreen
                    : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Title
            Text(
              type.title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.textGreen : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              type.subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Log Out
          _buildAccountTile(
            icon: Icons.logout_rounded,
            iconBackgroundColor: AppColors.surface,
            iconColor: AppColors.textSecondary,
            title: 'Log Out',
            onTap: _handleLogout,
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border.withValues(alpha: 0.5),
            indent: 72,
          ),

          // Delete Account
          _buildAccountTile(
            icon: Icons.delete_outline_rounded,
            iconBackgroundColor: AppColors.surfaceRed,
            iconColor: AppColors.error,
            title: 'Delete Account',
            titleColor: AppColors.error,
            onTap: _handleDeleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 4,
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: AppRadius.smBorder,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: titleColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
