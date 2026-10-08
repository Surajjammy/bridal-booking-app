import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';

/// Title row used at the top of every admin page.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: text.bodyMedium?.copyWith(
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final action in actions) ...[const SizedBox(width: 12), action],
      ],
    );
  }
}
