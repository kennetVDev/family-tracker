import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';
import '../theme/app_components.dart';

class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final ModernButtonVariant variant;
  final IconData? icon;
  final double? width;

  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.variant = ModernButtonVariant.primary,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final button = _buildButton();

    if (isFullWidth) {
      return SizedBox(
        width: width ?? double.infinity,
        height: 52,
        child: button,
      );
    }

    return SizedBox(
      width: width,
      height: 52,
      child: button,
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case ModernButtonVariant.primary:
        return _PrimaryButton(
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
        );
      case ModernButtonVariant.secondary:
        return _SecondaryButton(
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
        );
      case ModernButtonVariant.outlined:
        return _OutlinedButton(
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
        );
      case ModernButtonVariant.text:
        return _TextButton(
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
        );
      case ModernButtonVariant.danger:
        return _DangerButton(
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
        );
    }
  }
}

enum ModernButtonVariant { primary, secondary, outlined, text, danger }

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppGradients.primaryGradient : null,
        color: onPressed == null ? AppColors.textTertiary : null,
        borderRadius: AppBorderRadius.mdAll,
        boxShadow: onPressed != null ? AppShadows.button : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppBorderRadius.mdAll,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _SecondaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppGradients.secondaryGradient : null,
        color: onPressed == null ? AppColors.textTertiary : null,
        borderRadius: AppBorderRadius.mdAll,
        boxShadow: onPressed != null ? AppShadows.button : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppBorderRadius.mdAll,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _OutlinedButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: onPressed != null ? AppColors.primary : AppColors.textTertiary,
          width: 1.5,
        ),
        borderRadius: AppBorderRadius.mdAll,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppBorderRadius.mdAll,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        onPressed != null ? AppColors.primary : AppColors.textTertiary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: onPressed != null ? AppColors.primary : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: onPressed != null ? AppColors.primary : AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _TextButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppBorderRadius.mdAll,
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      onPressed != null ? AppColors.primary : AppColors.textTertiary,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: onPressed != null ? AppColors.primary : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: onPressed != null ? AppColors.primary : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _DangerButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? AppColors.error : AppColors.textTertiary,
        borderRadius: AppBorderRadius.mdAll,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppBorderRadius.mdAll,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppBorderRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppBorderRadius.mdAll,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        backgroundColor ?? AppColors.textPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: iconColor ?? AppColors.textPrimary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: textColor ?? AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}