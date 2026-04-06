import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/device_feedback_service.dart';
import '../services/notification_service.dart';
import '../models/notification_preferences_model.dart';
import '../widgets/settings/gentle_reminders_section.dart';
import '../widgets/settings/quiet_hours_section.dart';
import '../widgets/settings/device_feedback_section.dart';
import '../widgets/settings/account_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _feedbackService = DeviceFeedbackService();
  final _notificationService = NotificationService();

  DeviceFeedbackType _selectedFeedback = DeviceFeedbackType.vibration;
  bool _notificationsEnabled = false;
  int _frequency = 20;
  bool _isUnlimited = false;
  bool _quietHoursEnabled = false;
  String _quietStart = '22:00';
  String _quietEnd = '08:00';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final feedbackType = await _feedbackService.getFeedbackType();
      final notifPrefs = await _notificationService.getPreferences();
      if (mounted) {
        setState(() {
          _selectedFeedback = feedbackType;
          _notificationsEnabled = notifPrefs.enabled;
          _isUnlimited =
              notifPrefs.maxPerDay == 'unlimited' || notifPrefs.maxPerDay == null;
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationPreferences() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _notificationService.updatePreferences(
        enabled: _notificationsEnabled,
        maxPerDay: _isUnlimited ? 'unlimited' : _frequency,
        quietHours: QuietHours(
          enabled: _quietHoursEnabled,
          start: _quietStart,
          end: _quietEnd,
        ),
      );
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    final currentTime = _parseTime(isStart ? _quietStart : _quietEnd);
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted = _formatTime(picked);
      setState(() {
        if (isStart) _quietStart = formatted;
        else _quietEnd = formatted;
      });
      _updateNotificationPreferences();
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
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
      message: 'This is your last chance to keep your data. Delete your account permanently?',
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
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
                  _sectionHeader('Notifications'),
                  const SizedBox(height: AppSpacing.sm),
                  GentleRemindersSection(
                    enabled: _notificationsEnabled,
                    frequency: _frequency,
                    isUnlimited: _isUnlimited,
                    onEnabledChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                      _updateNotificationPreferences();
                    },
                    onFrequencyChanged: (v) => setState(() => _frequency = v),
                    onUnlimitedToggle: () {
                      setState(() => _isUnlimited = !_isUnlimited);
                      _updateNotificationPreferences();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_notificationsEnabled) ...[
                    QuietHoursSection(
                      enabled: _quietHoursEnabled,
                      quietStart: _quietStart,
                      quietEnd: _quietEnd,
                      onEnabledChanged: (v) {
                        setState(() => _quietHoursEnabled = v);
                        _updateNotificationPreferences();
                      },
                      onStartTap: () => _showTimePicker(true),
                      onEndTap: () => _showTimePicker(false),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  DeviceFeedbackSection(
                    selectedFeedback: _selectedFeedback,
                    onFeedbackTap: _onFeedbackOptionTap,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionHeader('Account'),
                  const SizedBox(height: AppSpacing.sm),
                  AccountSection(
                    onLogout: _handleLogout,
                    onDeleteAccount: _handleDeleteAccount,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
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
}
