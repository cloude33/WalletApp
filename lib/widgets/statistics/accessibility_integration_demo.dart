import 'package:flutter/material.dart';
import 'package:parion/widgets/statistics/accessibility_helpers.dart';
import 'package:parion/widgets/statistics/summary_card.dart';
import 'package:parion/widgets/statistics/metric_card.dart';
import 'package:parion/models/cash_flow_data.dart';

/// Comprehensive demo showing all accessibility features integrated
class AccessibilityIntegrationDemo extends StatefulWidget {
  const AccessibilityIntegrationDemo({super.key});

  @override
  State<AccessibilityIntegrationDemo> createState() =>
      _AccessibilityIntegrationDemoState();
}

class _AccessibilityIntegrationDemoState
    extends State<AccessibilityIntegrationDemo> {
  String _selectedPeriod = 'Bu Ay';
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erişilebilirlik Entegrasyonu'),
        actions: [
          AccessibleIconButton(
            icon: Icons.help_outline,
            onPressed: () => _showAccessibilityHelp(context),
            semanticLabel: 'Erişilebilirlik yardımı',
            tooltip: 'Erişilebilirlik özelliklerini göster',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period filter with accessible chips
          _buildPeriodFilter(),
          const SizedBox(height: 24),

          // Summary cards with accessibility
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Metric cards with accessibility
          _buildMetricCards(),
          const SizedBox(height: 24),

          // Progress indicators with accessibility
          _buildProgressSection(),
          const SizedBox(height: 24),

          // Action buttons with accessibility
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dönem Seçin',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AccessibleFilterChip(
              label: 'Bu Ay',
              selected: _selectedPeriod == 'Bu Ay',
              onTap: () => _selectPeriod('Bu Ay'),
              icon: Icons.calendar_today,
            ),
            AccessibleFilterChip(
              label: 'Geçen Ay',
              selected: _selectedPeriod == 'Geçen Ay',
              onTap: () => _selectPeriod('Geçen Ay'),
            ),
            AccessibleFilterChip(
              label: 'Bu Yıl',
              selected: _selectedPeriod == 'Bu Yıl',
              onTap: () => _selectPeriod('Bu Yıl'),
            ),
            AccessibleFilterChip(
              label: 'Özel',
              selected: _selectedPeriod == 'Özel',
              onTap: () => _selectPeriod('Özel'),
              icon: Icons.tune,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Özet Bilgiler',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Toplam Gelir',
                value: '₺15,000',
                subtitle: '+12% geçen aya göre',
                icon: Icons.trending_up,
                color: Colors.green,
                onTap: () {
                  StatisticsAccessibility.announce(
                    context,
                    'Gelir detayları açılıyor',
                  );
                  _showDetails = true;
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Toplam Gider',
                value: '₺8,500',
                subtitle: '-5% geçen aya göre',
                icon: Icons.trending_down,
                color: Colors.red,
                onTap: () {
                  StatisticsAccessibility.announce(
                    context,
                    'Gider detayları açılıyor',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metrikler',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Net Akış',
                value: '₺6,500',
                change: '+25%',
                trend: TrendDirection.up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Ortalama',
                value: '₺2,167',
                change: '+8%',
                trend: TrendDirection.up,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İlerleme Göstergeleri',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        AccessibleProgress(
          value: 0.75,
          label: 'Bütçe Kullanımı',
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        AccessibleProgress(
          value: 0.45,
          label: 'Tasarruf Hedefi',
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        AccessibleProgress(
          value: 0.90,
          label: 'Kredi Kartı Limiti',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'İşlemler',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        AccessibleButton(
          onPressed: () {
            StatisticsAccessibility.announce(
              context,
              'Rapor oluşturuluyor',
            );
            _generateReport();
          },
          semanticLabel: 'Rapor oluştur',
          semanticHint: 'Seçili dönem için finansal rapor oluşturur',
          child: const Text('Rapor Oluştur'),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AccessibleIconButton(
              icon: Icons.download,
              onPressed: () {
                StatisticsAccessibility.announce(
                  context,
                  'Rapor indiriliyor',
                );
              },
              semanticLabel: 'İndir',
              tooltip: 'Raporu indir',
            ),
            AccessibleIconButton(
              icon: Icons.share,
              onPressed: () {
                StatisticsAccessibility.announce(
                  context,
                  'Paylaşım seçenekleri açılıyor',
                );
              },
              semanticLabel: 'Paylaş',
              tooltip: 'Raporu paylaş',
            ),
            AccessibleIconButton(
              icon: Icons.print,
              onPressed: () {
                StatisticsAccessibility.announce(
                  context,
                  'Yazdırma ayarları açılıyor',
                );
              },
              semanticLabel: 'Yazdır',
              tooltip: 'Raporu yazdır',
            ),
          ],
        ),
      ],
    );
  }

  void _selectPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    StatisticsAccessibility.announce(
      context,
      '$period dönemi seçildi',
    );
  }

  void _generateReport() {
    // Simulate report generation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        StatisticsAccessibility.announce(
          context,
          'Rapor başarıyla oluşturuldu',
        );
      }
    });
  }

  void _showAccessibilityHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erişilebilirlik Özellikleri'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                Icons.touch_app,
                'Dokunma Alanları',
                'Tüm butonlar minimum 48x48 dp boyutundadır',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.record_voice_over,
                'Ekran Okuyucu',
                'TalkBack ve VoiceOver ile uyumludur',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.contrast,
                'Renk Kontrastı',
                'WCAG AA standardına uygun kontrast oranı',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.label,
                'Semantik Etiketler',
                'Tüm öğeler anlamlı açıklamalara sahiptir',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget to demonstrate contrast checking
class ContrastCheckerDemo extends StatefulWidget {
  const ContrastCheckerDemo({super.key});

  @override
  State<ContrastCheckerDemo> createState() => _ContrastCheckerDemoState();
}

class _ContrastCheckerDemoState extends State<ContrastCheckerDemo> {
  Color _foregroundColor = Colors.blue;
  Color _backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final hasGoodContrast = StatisticsAccessibility.hasGoodContrast(
      _foregroundColor,
      _backgroundColor,
    );

    final accessibleColor = StatisticsAccessibility.getAccessibleColor(
      _foregroundColor,
      _backgroundColor,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontrast Kontrolü'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Renk Kontrastı Testi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: _backgroundColor,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Orijinal Renk',
                      style: TextStyle(
                        color: _foregroundColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erişilebilir Renk',
                      style: TextStyle(
                        color: accessibleColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasGoodContrast ? Icons.check_circle : Icons.warning,
                          color: hasGoodContrast ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasGoodContrast
                              ? 'İyi Kontrast (WCAG AA)'
                              : 'Düşük Kontrast (Düzeltildi)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kontrast Oranı: ${_calculateContrastRatio(_foregroundColor, _backgroundColor).toStringAsFixed(2)}:1',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Minimum Gereksinim: 4.5:1 (WCAG AA)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Ön Plan Rengi:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildColorButton(Colors.blue, 'Mavi'),
                _buildColorButton(Colors.red, 'Kırmızı'),
                _buildColorButton(Colors.green, 'Yeşil'),
                _buildColorButton(Colors.yellow.shade200, 'Sarı'),
                _buildColorButton(Colors.grey.shade300, 'Gri'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Arka Plan Rengi:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildBackgroundButton(Colors.white, 'Beyaz'),
                _buildBackgroundButton(Colors.black, 'Siyah'),
                _buildBackgroundButton(Colors.grey.shade200, 'Açık Gri'),
                _buildBackgroundButton(Colors.grey.shade800, 'Koyu Gri'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color, String label) {
    return ElevatedButton(
      onPressed: () => setState(() => _foregroundColor = color),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  Widget _buildBackgroundButton(Color color, String label) {
    return ElevatedButton(
      onPressed: () => setState(() => _backgroundColor = color),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == Colors.white ? Colors.black : Colors.white,
      ),
      child: Text(label),
    );
  }

  double _calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }
}
