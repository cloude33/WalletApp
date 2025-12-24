import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                  const SizedBox(height: 20),
                  // App Icon
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00BFA5),
                            Color(0xFF00D4B8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BFA5).withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  const Center(
                    child: Text(
                      'WalletApp',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Version
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Versiyon 1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Developer Section
                  _buildSection(context, 'GELİŞTİRİCİ', [
                    _buildInfoCard(
                      context,
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF5E5CE6),
                      title: 'Geliştirici',
                      value: 'Hüseyin BULUT',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF007AFF),
                      title: 'Web Sitesi',
                      value: 'Yakında',
                      isClickable: false,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.email_rounded,
                      iconColor: const Color(0xFFFF9500),
                      title: 'İletişim',
                      value: 'hbulut77@gmail.com',
                      isClickable: true,
                      onTap: () => _launchUrl('mailto:hbulut77@gmail.com'),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.code_rounded,
                      iconColor: const Color(0xFF1C1C1E),
                      title: 'GitHub',
                      value: 'cloude33',
                      isClickable: true,
                      onTap: () => _launchUrl('https://github.com/cloude33'),
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  // Legal Section
                  _buildSection(context, 'YASAL', [
                    _buildActionCard(
                      context,
                      icon: Icons.privacy_tip_rounded,
                      iconColor: const Color(0xFF34C759),
                      title: 'Gizlilik Politikası',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gizlilik Politikası yakında eklenecek'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      icon: Icons.description_rounded,
                      iconColor: const Color(0xFFFF9500),
                      title: 'Kullanım Koşulları',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kullanım Koşulları yakında eklenecek'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      icon: Icons.article_rounded,
                      iconColor: const Color(0xFF007AFF),
                      title: 'Açık Kaynak Lisansları',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lisanslar yakında eklenecek'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 40),
                  
                  // Copyright
                  Center(
                    child: Text(
                      '© 2025 WalletApp',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF8E8E93).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tüm hakları saklıdır',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8E8E93).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF00BFA5),
              size: 24,
            ),
          ),
          const Expanded(
            child: Text(
              'Hakkında',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isClickable ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isClickable
                            ? const Color(0xFF007AFF)
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClickable)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF8E8E93),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF8E8E93),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
