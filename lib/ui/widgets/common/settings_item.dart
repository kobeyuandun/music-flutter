import 'package:flutter/material.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).primaryColor)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),

            // Trailing
            if (trailing != null)
              trailing!
            else
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).disabledColor,
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsSwitchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? iconColor;

  const SettingsSwitchItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: onChanged != null ? () => onChanged!(!value) : null,
    );
  }
}
