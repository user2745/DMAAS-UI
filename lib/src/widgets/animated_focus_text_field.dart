import 'package:flutter/material.dart';

// Design Language: Focus animations (200ms) for inputs
// See DESIGN_LANGUAGE.md section "Input Focus Animations"
// Standardized on 8px grid, consistent shadow lift, and primary-colored borders on focus.

class AnimatedFocusTextField extends StatefulWidget {
  const AnimatedFocusTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.filled = false,
    this.fillColor,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool filled;
  final Color? fillColor;

  @override
  State<AnimatedFocusTextField> createState() => _AnimatedFocusTextFieldState();
}

class _AnimatedFocusTextFieldState extends State<AnimatedFocusTextField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _hasFocus
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          filled: widget.filled,
          fillColor: widget.fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
          ),
        ),
      ),
    );
  }
}
