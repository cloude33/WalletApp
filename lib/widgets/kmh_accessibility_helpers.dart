import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
class KmhAccessibility {
  static void announce(BuildContext context, String message) {
    final view = View.of(context);
    SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
  }
  static String currencyLabel(double amount, {bool isDebt = false}) {
    final absAmount = amount.abs();
    final formattedAmount = absAmount.toStringAsFixed(2);

    if (isDebt || amount < 0) {
      return '$formattedAmount Türk Lirası borç';
    } else {
      return '$formattedAmount Türk Lirası';
    }
  }
  static String percentageLabel(double percentage) {
    return 'Yüzde ${percentage.toStringAsFixed(1)}';
  }
  static String dateLabel(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  static String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }
  static String transactionTypeLabel(String type) {
    switch (type) {
      case 'withdrawal':
        return 'Para çekme işlemi';
      case 'deposit':
        return 'Para yatırma işlemi';
      case 'interest':
        return 'Faiz tahakkuku';
      case 'fee':
        return 'Masraf';
      case 'transfer':
        return 'Transfer işlemi';
      default:
        return 'İşlem';
    }
  }
}
class KmhAccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final bool isEnabled;

  const KmhAccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: isEnabled && onPressed != null,
      child: ElevatedButton(onPressed: onPressed, child: child),
    );
  }
}
class KmhAccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Color? color;

  const KmhAccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip ?? semanticLabel,
        color: color,
      ),
    );
  }
}
class KmhAccessibleCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const KmhAccessibleCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        margin: margin,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
class KmhAccessibleProgress extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  final Color backgroundColor;
  final double height;

  const KmhAccessibleProgress({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.backgroundColor = Colors.grey,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toStringAsFixed(0);

    return Semantics(
      label: '$label: Yüzde $percentage',
      value: percentage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: backgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: height,
        ),
      ),
    );
  }
}
class KmhAccessibleListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String semanticLabel;

  const KmhAccessibleListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
