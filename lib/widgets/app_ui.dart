import 'package:flutter/material.dart';

import '../theme/app_design_system.dart';
import '../utils/text_case.dart';
import 'premium_states.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title.toTitleCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.3,
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
        if (subtitle?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(.62),
            ),
          ),
        ],
        if (showDivider) ...[
          const SizedBox(height: AppSpacing.sm),
          Divider(
            height: 1,
            thickness: .7,
            color: theme.colorScheme.outlineVariant.withOpacity(.46),
          ),
        ],
      ],
    );
  }
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadii.large,
    this.raised = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withOpacity(.72),
      ),
      boxShadow: raised ? AppElevation.soft(context) : null,
    );
    final content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class AppSaveButton extends StatelessWidget {
  const AppSaveButton({
    super.key,
    required this.saved,
    required this.onPressed,
    this.tooltip,
  });

  final bool saved;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withOpacity(.94),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip ?? (saved ? 'Remove from saved' : 'Save'),
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(
          saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color:
              saved ? theme.colorScheme.secondary : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

enum AppStateKind { empty, error, offline }

class AppStatePanel extends StatelessWidget {
  const AppStatePanel({
    super.key,
    required this.title,
    required this.message,
    required this.kind,
    this.onRetry,
    this.actionLabel = 'Retry',
  });

  final String title;
  final String message;
  final AppStateKind kind;
  final VoidCallback? onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (kind) {
      AppStateKind.empty => Icons.search_off_rounded,
      AppStateKind.error => Icons.error_outline_rounded,
      AppStateKind.offline => Icons.cloud_off_rounded,
    };
    final accent = kind == AppStateKind.error ? colors.error : colors.primary;
    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withOpacity(.12),
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toTitleCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppOfflineBanner extends StatelessWidget {
  const AppOfflineBanner({
    super.key,
    this.message = 'You appear to be offline.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.onErrorContainer),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class AppDiscoverySkeleton extends StatelessWidget {
  const AppDiscoverySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        PremiumSkeleton(height: 58, borderRadius: AppRadii.medium),
        SizedBox(height: AppSpacing.md),
        PremiumSkeleton(height: 112, borderRadius: AppRadii.large),
        SizedBox(height: AppSpacing.sm),
        PremiumSkeleton(height: 112, borderRadius: AppRadii.large),
        SizedBox(height: AppSpacing.sm),
        PremiumSkeleton(height: 112, borderRadius: AppRadii.large),
      ],
    );
  }
}

class AppStatData {
  const AppStatData({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;
}

class AppEqualStats extends StatelessWidget {
  const AppEqualStats({super.key, required this.items});

  final List<AppStatData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.compact;
        return SizedBox(
          height: 78,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _AppStatBox(data: items[index], compact: compact),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AppStatBox extends StatelessWidget {
  const _AppStatBox({required this.data, required this.compact});

  final AppStatData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xxs : AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.42),
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(.65),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (data.icon != null) ...[
            Icon(data.icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(height: 3),
          ],
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(.62),
            ),
          ),
        ],
      ),
    );
  }
}
