import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _agreedToTerms = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _showErrorSnackBar('Please agree to the Terms & Privacy Policy');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        // Send email verification
        await _authService.sendEmailVerification();

        // Show success message and pop back
        _showSuccessSnackBar('Account created! Please verify your email.');
        Navigator.pop(context);
      } else {
        _showErrorSnackBar(result.errorMessage!);
      }
    }
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service content goes here...\n\n'
            'By using this app, you agree to these terms.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy content goes here...\n\n'
            'We respect your privacy and protect your data.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildForm(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFooter(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text('Create Account', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Begin your journey to calm',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Email',
            hintText: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Name',
            hintText: 'John Doe',
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPasswordField(
            label: 'Password',
            controller: _passwordController,
            helperText: 'Minimum 8 characters',
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPasswordField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSignUp(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTermsCheckbox(),
          const SizedBox(height: AppSpacing.lg),
          _buildDisclaimer(),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Create Account',
            isLoading: _isLoading,
            onPressed: _handleSignUp,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() => _agreedToTerms = value ?? false);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: AppColors.textHint, width: 1.5),
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms',
                  style: AppTextStyles.link,
                  recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: AppTextStyles.link,
                  recognizer: TapGestureRecognizer()
                    ..onTap = _showPrivacyDialog,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdBorder,
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          children: [
            TextSpan(
              text: 'Disclaimer: ',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(
              text:
                  'This app is for stress support and wellness tracking only. It does not provide medical diagnosis or treatment.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppTextButton(text: 'Log in', onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
