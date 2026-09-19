import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AnimatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool showSuccessIndicator;
  final bool shouldShakeOnError;

  const AnimatedTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.showSuccessIndicator = true,
    this.shouldShakeOnError = true,
  });

  @override
  State<AnimatedTextField> createState() => AnimatedTextFieldState();
}

class AnimatedTextFieldState extends State<AnimatedTextField> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  String? _internalErrorText;
  bool _isFocused = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText && widget.errorText != null) {
      if (widget.shouldShakeOnError) {
        shake();
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (!_isFocused && _isDirty && widget.validator != null) {
          final val = widget.controller?.text;
          _internalErrorText = widget.validator!(val);
        }
      });
    }
  }

  /// Triggers a haptic feedback and shake animation
  void shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeError = widget.errorText ?? _internalErrorText;
    final hasError = activeError != null && activeError.isNotEmpty;
    final textVal = widget.controller?.text ?? '';
    final isValid = !hasError && _isDirty && textVal.isNotEmpty && widget.validator != null && widget.validator!(textVal) == null;

    final Color borderColor;
    if (hasError) {
      borderColor = AppTheme.urgentText;
    } else if (_isFocused) {
      borderColor = AppTheme.electricCobalt;
    } else if (isValid && widget.showSuccessIndicator) {
      borderColor = AppTheme.successText;
    } else {
      borderColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.5);
    }

    final Color fillColor;
    if (hasError) {
      fillColor = isDark ? Colors.red.shade900.withValues(alpha: 0.1) : Colors.red.shade50.withValues(alpha: 0.4);
    } else if (_isFocused) {
      fillColor = isDark ? AppTheme.darkSurfaceCard : Colors.white;
    } else {
      fillColor = isDark ? AppTheme.darkSurfaceCard : Colors.white;
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = sin(_shakeAnimation.value * pi * 4) * (1 - _shakeAnimation.value) * 8;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _isFocused || hasError ? 1.8 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: (hasError ? AppTheme.urgentText : AppTheme.electricCobalt).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.textDark,
              ),
              onTap: widget.onTap,
              onChanged: (val) {
                if (!_isDirty) setState(() => _isDirty = true);
                if (widget.validator != null) {
                  final err = widget.validator!(val);
                  if (err != _internalErrorText) {
                    setState(() => _internalErrorText = err);
                  }
                }
                widget.onChanged?.call(val);
              },
              onFieldSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                alignLabelWithHint: widget.maxLines > 1,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: hasError
                      ? AppTheme.urgentText
                      : (_isFocused ? AppTheme.electricCobalt : (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
                ),
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextMuted.withValues(alpha: 0.6) : AppTheme.textMuted.withValues(alpha: 0.6),
                ),
                prefixIcon: widget.prefixIcon,
                suffixIcon: _buildSuffixIcon(isValid, hasError, isDark),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                counterText: '',
              ),
            ),
          ),
          // Animated Error Message Reveal
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topLeft,
            child: hasError
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 13,
                          color: AppTheme.urgentText,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            activeError,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.urgentText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isValid, bool hasError, bool isDark) {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (hasError) {
      return const Icon(
        Icons.error_rounded,
        color: AppTheme.urgentText,
        size: 18,
      );
    }

    if (isValid && widget.showSuccessIndicator) {
      return const AnimatedScale(
        scale: 1.0,
        duration: Duration(milliseconds: 200),
        child: Icon(
          Icons.check_circle_rounded,
          color: AppTheme.successText,
          size: 18,
        ),
      );
    }

    return null;
  }
}
