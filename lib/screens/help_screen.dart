import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildFaqItem(
                    context,
                    'Nasıl işlem eklerim?',
                    'Ana sayfadaki veya alt menüdeki "+" butonuna tıklayarak yeni bir gelir veya gider işlemi ekleyebilirsiniz.',
                  ),
                  _buildFaqItem(
                    context,
                    'Bütçe nasıl oluşturulur?',
                    'Ana sayfada "Bütçeler" bölümündeki "+" butonuna tıklayarak aylık harcama limitlerinizi belirleyebilirsiniz.',
                  ),
                  _buildFaqItem(
                    context,
                    'Verilerim nerede saklanıyor?',
                    'Tüm verileriniz cihazınızda güvenli bir şekilde saklanmaktadır. Ayarlar menüsünden yedekleme yapabilirsiniz.',
                  ),
                  _buildFaqItem(
                    context,
                    'Para birimini değiştirebilir miyim?',
                    'Evet, Ayarlar > Para Birimi menüsünden istediğiniz para birimini seçebilirsiniz.',
                  ),
                  _buildFaqItem(
                    context,
                    'Kategorileri düzenleyebilir miyim?',
                    'Alt menüden "Kategori" sekmesine giderek yeni kategoriler ekleyebilir veya mevcutları düzenleyebilirsiniz.',
                  ),
                  _buildFaqItem(
                    context,
                    'Karanlık mod var mı?',
                    'Evet, Ayarlar > Tema menüsünden Açık, Koyu veya Sistem temasını seçebilirsiniz.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.support_agent,
                          size: 48,
                          color: Color(0xFF00BFA5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Daha fazla yardıma mı ihtiyacınız var?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bizimle iletişime geçmekten çekinmeyin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Destek ekibine yönlendiriliyorsunuz...',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'İletişime Geç',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFF00BFA5),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Yardım & Destek',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
