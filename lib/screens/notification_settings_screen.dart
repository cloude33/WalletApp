import 'package:flutter/material.dart';
import '../models/notification_preferences.dart';
import '../services/notification_preferences_service.dart';
import '../services/notification_service.dart';
import 'kmh_alert_settings_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationPreferencesService _prefsService =
      NotificationPreferencesService();
  final NotificationService _notificationService = NotificationService();

  NotificationPreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  String _getPaymentReminderDaysText() {
    if (_preferences!.paymentReminderDays.isEmpty) {
      return 'Seçilmedi';
    }
    
    final sortedDays = List<int>.from(_preferences!.paymentReminderDays)..sort();
    if (sortedDays.length == 1) {
      return '${sortedDays.first} gün önce';
    } else {
      return '${sortedDays.map((d) => '$d gün').join(', ')} önce';
    }
  }

  Future<void> _showPaymentReminderDaysPicker(BuildContext context) async {
    List<int> selectedDays = List<int>.from(_preferences!.paymentReminderDays);
    final availableDays = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal', style: TextStyle(color: Colors.red)),
                        ),
                        const Text(
                          'Hatırlatma Günleri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _preferences = _preferences!.copyWith(
                                paymentReminderDays: selectedDays,
                              );
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  // Subtitle
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Son ödeme tarihinden önce hatırlatılacak günleri seçin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Days List
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableDays.length,
                      itemBuilder: (context, index) {
                        final day = availableDays[index];
                        final isSelected = selectedDays.contains(day);
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected 
                              ? Border.all(color: Colors.blue, width: 1)
                              : null,
                          ),
                          child: ListTile(
                            title: Text(
                              '$day gün önce',
                              style: TextStyle(
                                color: isSelected ? Colors.blue : Colors.black,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : const Icon(Icons.circle_outlined, color: Colors.grey),
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedDays.remove(day);
                                } else {
                                  selectedDays.add(day);
                                }
                                selectedDays.sort();
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // Clear All Button
                  if (selectedDays.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: TextButton(
                        onPressed: () {
                          setModalState(() {
                            selectedDays.clear();
                          });
                        },
                        child: const Text(
                          'Tümünü Temizle',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDaysPicker({
    required BuildContext context,
    required String title,
    required int currentValue,
    required int minValue,
    required int maxValue,
    required Function(int) onChanged,
  }) async {
    int selectedValue = currentValue;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal', style: TextStyle(color: Colors.red)),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onChanged(selectedValue);
                        Navigator.pop(context);
                      },
                      child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              // Picker
              Expanded(
                child: ListView.builder(
                  itemCount: maxValue - minValue + 1,
                  itemBuilder: (context, index) {
                    final value = minValue + index;
                    final isSelected = value == selectedValue;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                        border: isSelected 
                          ? Border.all(color: Colors.blue, width: 1)
                          : null,
                      ),
                      child: ListTile(
                        title: Text(
                          '$value gün önce',
                          style: TextStyle(
                            color: isSelected ? Colors.blue : Colors.black,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected 
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                        onTap: () {
                          selectedValue = value;
                          onChanged(selectedValue);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test bildirimi gönderildi! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test bildirimi gönderilemedi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefsService.getPreferences();
    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    if (_preferences != null) {
      await _prefsService.savePreferences(_preferences!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ayarlar kaydedildi')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Bildirimi Gönder',
            onPressed: _sendTestNotification,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestSection(),
          const SizedBox(height: 24),
          _buildDailySummarySection(),
          const SizedBox(height: 24),
          _buildWeeklySummarySection(),
          const SizedBox(height: 24),
          _buildBillRemindersSection(),
          const SizedBox(height: 24),
          _buildInstallmentRemindersSection(),
          const SizedBox(height: 24),
          _buildPaymentRemindersSection(),
          const SizedBox(height: 24),
          _buildLimitAlertsSection(),
          const SizedBox(height: 24),
          _buildStatementCutNotificationsSection(),
          const SizedBox(height: 24),
          _buildInstallmentEndingNotificationsSection(),
          const SizedBox(height: 24),
          _buildKmhNotificationsSection(),
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Bildirim Testi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Bildirim sisteminin çalışıp çalışmadığını test edin.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.send),
                label: const Text('Test Bildirimi Gönder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Günlük Özet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Günlük özet bildirimi'),
              value: _preferences!.dailySummaryEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    dailySummaryEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.dailySummaryEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Bildirim saati'),
                subtitle: Text(
                  '${_preferences!.dailySummaryTime.hour.toString().padLeft(2, '0')}:'
                  '${_preferences!.dailySummaryTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _preferences!.dailySummaryTime,
                  );
                  if (time != null) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        dailySummaryTime: time,
                      );
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Haftalık Özet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Haftalık özet bildirimi'),
              subtitle: const Text('Her Pazartesi'),
              value: _preferences!.weeklySummaryEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    weeklySummaryEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.weeklySummaryEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Bildirim saati'),
                subtitle: Text(
                  '${_preferences!.weeklySummaryTime.hour.toString().padLeft(2, '0')}:'
                  '${_preferences!.weeklySummaryTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _preferences!.weeklySummaryTime,
                  );
                  if (time != null) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        weeklySummaryTime: time,
                      );
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBillRemindersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fatura Hatırlatıcıları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Fatura hatırlatıcıları'),
              value: _preferences!.billRemindersEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    billRemindersEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.billRemindersEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Kaç gün önce hatırlat'),
                subtitle: Text('${_preferences!.billReminderDays} gün önce'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showDaysPicker(
                  context: context,
                  title: 'Fatura Hatırlatma Günü',
                  currentValue: _preferences!.billReminderDays,
                  minValue: 1,
                  maxValue: 7,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        billReminderDays: value,
                      );
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentRemindersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Taksit Hatırlatıcıları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Taksit hatırlatıcıları'),
              value: _preferences!.installmentRemindersEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    installmentRemindersEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.installmentRemindersEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Kaç gün önce hatırlat'),
                subtitle: Text(
                  '${_preferences!.installmentReminderDays} gün önce',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showDaysPicker(
                  context: context,
                  title: 'Taksit Hatırlatma Günü',
                  currentValue: _preferences!.installmentReminderDays,
                  minValue: 1,
                  maxValue: 10,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        installmentReminderDays: value,
                      );
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRemindersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kredi Kartı Ödeme Hatırlatmaları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Ödeme hatırlatmaları'),
              subtitle: const Text('Son ödeme tarihinden önce hatırlat'),
              value: _preferences!.paymentRemindersEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    paymentRemindersEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.paymentRemindersEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Hatırlatma günleri'),
                subtitle: Text(_getPaymentReminderDaysText()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showPaymentReminderDaysPicker(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLimitAlertsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Limit Uyarıları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Limit uyarıları'),
              subtitle: const Text('Kart limitine yaklaşıldığında uyar'),
              value: _preferences!.limitAlertsEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    limitAlertsEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.limitAlertsEnabled) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Uyarı eşikleri (limit kullanım oranı)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              CheckboxListTile(
                title: const Text('%80 limite ulaşıldığında'),
                value: _preferences!.limitAlertThresholds.contains(80.0),
                onChanged: (value) {
                  setState(() {
                    final thresholds = List<double>.from(_preferences!.limitAlertThresholds);
                    if (value == true) {
                      if (!thresholds.contains(80.0)) thresholds.add(80.0);
                    } else {
                      thresholds.remove(80.0);
                    }
                    thresholds.sort();
                    _preferences = _preferences!.copyWith(
                      limitAlertThresholds: thresholds,
                    );
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('%90 limite ulaşıldığında'),
                value: _preferences!.limitAlertThresholds.contains(90.0),
                onChanged: (value) {
                  setState(() {
                    final thresholds = List<double>.from(_preferences!.limitAlertThresholds);
                    if (value == true) {
                      if (!thresholds.contains(90.0)) thresholds.add(90.0);
                    } else {
                      thresholds.remove(90.0);
                    }
                    thresholds.sort();
                    _preferences = _preferences!.copyWith(
                      limitAlertThresholds: thresholds,
                    );
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('%100 limite ulaşıldığında'),
                value: _preferences!.limitAlertThresholds.contains(100.0),
                onChanged: (value) {
                  setState(() {
                    final thresholds = List<double>.from(_preferences!.limitAlertThresholds);
                    if (value == true) {
                      if (!thresholds.contains(100.0)) thresholds.add(100.0);
                    } else {
                      thresholds.remove(100.0);
                    }
                    thresholds.sort();
                    _preferences = _preferences!.copyWith(
                      limitAlertThresholds: thresholds,
                    );
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatementCutNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ekstre Kesim Bildirimleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Ekstre kesim bildirimleri'),
              subtitle: const Text('Ekstre kesildiğinde bildirim al'),
              value: _preferences!.statementCutNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    statementCutNotificationsEnabled: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentEndingNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Taksit Bitişi Bildirimleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Taksit bitişi bildirimleri'),
              subtitle: const Text('Taksit son ödemeye ulaştığında bildirim al'),
              value: _preferences!.installmentEndingNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    installmentEndingNotificationsEnabled: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKmhNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KMH Bildirimleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kredili Mevduat Hesabı (KMH) bildirimleri için ayarlar',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Limit Uyarıları'),
              subtitle: const Text('KMH limit kullanımı uyarıları'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KmhAlertSettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.blue),
              title: const Text('Faiz Bildirimleri'),
              subtitle: const Text('Günlük faiz tahakkuku bildirimleri'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KmhAlertSettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('Ödeme Hatırlatıcıları'),
              subtitle: const Text('Ödeme planı hatırlatıcıları'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ödeme hatırlatıcıları ödeme planı ekranından yönetilir'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

