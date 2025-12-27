import 'package:flutter/material.dart';

class GradientDemoScreen extends StatelessWidget {
  const GradientDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gradient Seçenekleri'),
        backgroundColor: Colors.black87,
      ),
      body: ListView(
        children: [
          _buildGradientOption(
            context,
            title: 'Seçenek 1: Modern Mavi-Mor',
            subtitle: 'Fintech Tarzı - Güven Veren',
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          _buildGradientOption(
            context,
            title: 'Seçenek 2: Profesyonel Lacivert-Turkuaz',
            subtitle: 'Bankacılık Tarzı - Çok Profesyonel',
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0f2027),
                Color(0xFF203a43),
                Color(0xFF2c5364),
              ],
            ),
          ),
          _buildGradientOption(
            context,
            title: 'Seçenek 3: Altın-Turuncu',
            subtitle: 'Mevcut Temanıza Uygun - Enerjik',
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFf12711),
                Color(0xFFf5af19),
              ],
            ),
          ),
          _buildGradientOption(
            context,
            title: 'Seçenek 4: Koyu Yeşil-Mavi',
            subtitle: 'Para/Finans Temalı - Güven Veren',
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF134e5e),
                Color(0xFF71b280),
              ],
            ),
          ),
          _buildGradientOption(
            context,
            title: 'Seçenek 5: Premium Siyah-Gri',
            subtitle: 'Lüks Görünüm - Minimalist',
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF232526),
                Color(0xFF414345),
              ],
            ),
          ),
          _buildGradientOption(
            context,
            title: 'Seçenek 6: Koyu Mavi-Yeşil',
            subtitle: 'Modern ve Sakin - Premium',
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1e3c72),
                Color(0xFF2a5298),
              ],
            ),
          ),
          _buildGradientOption(
            context,
            title: 'Seçenek 7: Yumuşak Mor-Pembe',
            subtitle: 'Modern ve Şık - Yumuşak',
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8E2DE2),
                Color(0xFF4A00E0),
              ],
            ),
          ),
          _buildGradientOption(
            context,
            title: 'Seçenek 8: Koyu Turuncu-Kırmızı',
            subtitle: 'Cesur ve Enerjik - Dikkat Çekici',
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEB3349),
                Color(0xFFF45C43),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required LinearGradient gradient,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 200,
          decoration: BoxDecoration(gradient: gradient),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hoş Geldin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HÜSEYİN BULUT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
