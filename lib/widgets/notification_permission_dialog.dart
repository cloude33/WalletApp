import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_scheduler_service.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bildirim İzni'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bütçe uyarıları, hatırlatıcılar ve özetler için bildirim izni gerekiyor.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'İzin vermeniz durumunda:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('• Bütçe limitine yaklaştığınızda uyarı alırsınız'),
          Text('• Fatura ve taksit hatırlatıcıları alırsınız'),
          Text('• Günlük ve haftalık özetler alırsınız'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Şimdi Değil'),
        ),
        ElevatedButton(
          onPressed: () async {
            final granted = await _requestPermission();
            if (context.mounted) {
              Navigator.pop(context, granted);
            }
          },
          child: const Text('İzin Ver'),
        ),
      ],
    );
  }

  Future<bool> _requestPermission() async {
    final schedulerService = NotificationSchedulerService();
    return await schedulerService.requestPermissions();
  }

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NotificationPermissionDialog(),
    );
    return result ?? false;
  }

  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim İzni Reddedildi'),
        content: const Text(
          'Bildirimler için izin reddedildi. Ayarlardan izin verebilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () async {
              await openAppSettings();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  static Future<PermissionStatus> checkPermissionStatus() async {
    return await Permission.notification.status;
  }
}
