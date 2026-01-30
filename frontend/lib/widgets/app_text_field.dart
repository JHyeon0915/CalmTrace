import 'package:flutter/material.dart';

/// Custom styled text field matching the app's design system
class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            counterText: '',
          ),
        ),
        if (helperText != null && errorText == null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }
}

/// Password text field with visibility toggle
class AppPasswordField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  const AppPasswordField({
    super.key,
    required this.label,
    this.hintText = '••••••••',
    this.helperText,
    this.controller,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      controller: widget.controller,
      textInputAction: widget.textInputAction,
      obscureText: _obscureText,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.grey.shade400,
          size: 20,
        ),
        onPressed: () {
          setState(() => _obscureText = !_obscureText);
        },
      ),
    );
  }
}
