import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';

/// A titled card that groups related form fields.
class SectionCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleLarge),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: text.bodyMedium?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
