import 'package:flutter/material.dart';
import 'package:parion/widgets/statistics/accessibility_helpers.dart';

/// Example demonstrating accessibility features in statistics widgets
class AccessibilityExample extends StatelessWidget {
  const AccessibilityExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erişilebilirlik Özellikleri'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Erişilebilir Butonlar',
            'Minimum 48x48 dokunma alanı',
            _buildAccessibleButtons(context),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Erişilebilir Kartlar',
            'Semantik etiketler ve dokunma alanları',
            _buildAccessibleCards(context),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Renk Kontrastı',
            'WCAG AA standardı (4.5:1)',
            _buildContrastExamples(context),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'İlerleme Göstergeleri',
            'Semantik değerler ile',
            _buildProgressExamples(context),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Filtre Chip\'leri',
            'Seçim durumu bildirimi',
            _buildFilterChipExamples(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildAccessibleButtons(BuildContext context) {
    return Column(
      children: [
        AccessibleButton(
          onPressed: () {
            StatisticsAccessibility.announce(
              context,
              'Rapor oluşturuldu',
            );
          },
          semanticLabel: 'Rapor oluştur',
          semanticHint: 'Yeni bir finansal rapor oluşturmak için dokunun',
          child: const Text('Rapor Oluştur'),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AccessibleIconButton(
              icon: Icons.download,
              onPressed: () {},
              semanticLabel: 'İndir',
              tooltip: 'Raporu indir',
            ),
            AccessibleIconButton(
              icon: Icons.share,
              onPressed: () {},
              semanticLabel: 'Paylaş',
              tooltip: 'Raporu paylaş',
            ),
            AccessibleIconButton(
              icon: Icons.print,
              onPressed: () {},
              semanticLabel: 'Yazdır',
              tooltip: 'Raporu yazdır',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccessibleCards(BuildContext context) {
    return Column(
      children: [
        AccessibleCard(
          semanticLabel: 'Toplam gelir: 15,000 Türk Lirası, Geçen aya göre yüzde 12 artış',
          onTap: () {
            StatisticsAccessibility.announce(
              context,
              'Gelir detayları açılıyor',
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Toplam Gelir',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₺15,000',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '+12% geçen aya göre',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AccessibleListTile(
          leading: const Icon(Icons.account_balance_wallet),
          title: const Text('Nakit'),
          subtitle: const Text('₺5,000'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
          semanticLabel: 'Nakit: 5,000 Türk Lirası, detayları görmek için dokunun',
        ),
      ],
    );
  }

  Widget _buildContrastExamples(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.cardColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContrastExample(
              context,
              'İyi Kontrast',
              Colors.blue,
              backgroundColor,
              true,
            ),
            const SizedBox(height: 12),
            _buildContrastExample(
              context,
              'Düşük Kontrast (Otomatik Düzeltildi)',
              Colors.yellow.shade200,
              backgroundColor,
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContrastExample(
    BuildContext context,
    String label,
    Color originalColor,
    Color backgroundColor,
    bool hasGoodContrast,
  ) {
    final accessibleColor = StatisticsAccessibility.getAccessibleColor(
      originalColor,
      backgroundColor,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 4),
              Text(
                'Kontrast: ${hasGoodContrast ? "✓ İyi" : "✗ Düzeltildi"}',
                style: TextStyle(
                  fontSize: 12,
                  color: hasGoodContrast ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: accessibleColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'Metin',
              style: TextStyle(
                color: backgroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressExamples(BuildContext context) {
    return Column(
      children: [
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

  Widget _buildFilterChipExamples(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AccessibleFilterChip(
          label: 'Bu Ay',
          selected: true,
          onTap: () {},
          icon: Icons.calendar_today,
        ),
        AccessibleFilterChip(
          label: 'Geçen Ay',
          selected: false,
          onTap: () {},
        ),
        AccessibleFilterChip(
          label: 'Bu Yıl',
          selected: false,
          onTap: () {},
        ),
        AccessibleFilterChip(
          label: 'Özel',
          selected: false,
          onTap: () {},
          icon: Icons.tune,
        ),
      ],
    );
  }
}

/// Accessibility testing widget
class AccessibilityTestWidget extends StatelessWidget {
  const AccessibilityTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erişilebilirlik Testi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Erişilebilirlik Kontrol Listesi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildChecklistItem(
              '✓ Minimum dokunma alanı: 48x48 dp',
              Colors.green,
            ),
            _buildChecklistItem(
              '✓ Semantik etiketler tüm interaktif öğelerde',
              Colors.green,
            ),
            _buildChecklistItem(
              '✓ Renk kontrastı WCAG AA standardı (4.5:1)',
              Colors.green,
            ),
            _buildChecklistItem(
              '✓ Ekran okuyucu desteği',
              Colors.green,
            ),
            _buildChecklistItem(
              '✓ Klavye navigasyonu',
              Colors.green,
            ),
            _buildChecklistItem(
              '✓ Odak göstergeleri',
              Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Test Senaryoları',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildTestScenario(
              '1. Ekran Okuyucu Testi',
              'TalkBack (Android) veya VoiceOver (iOS) ile tüm öğelerin okunabildiğini doğrulayın.',
            ),
            _buildTestScenario(
              '2. Dokunma Alanı Testi',
              'Tüm butonların ve interaktif öğelerin kolayca dokunulabildiğini test edin.',
            ),
            _buildTestScenario(
              '3. Kontrast Testi',
              'Hem açık hem karanlık modda tüm metinlerin okunabilir olduğunu kontrol edin.',
            ),
            _buildTestScenario(
              '4. Klavye Navigasyonu',
              'Tab tuşu ile tüm interaktif öğeler arasında gezinebildiğinizi test edin.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildTestScenario(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
    );
  }
}
