import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? moreText;
  final VoidCallback? onMoreTap;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.moreText,
    this.onMoreTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
          if (onMoreTap != null)
            TextButton.icon(
              onPressed: onMoreTap,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: Text(moreText ?? '更多'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }
}
