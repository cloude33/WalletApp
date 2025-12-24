import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  final ThemeService _themeService = ThemeService();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await _themeService.getThemeMode();

    if (!mounted) return;

    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark =
        theme == ThemeMode.dark ||
        (theme == ThemeMode.system && brightness == Brightness.dark);

    setState(() {
      _isDark = isDark;
      if (_isDark) {
        _animationController.value = 1;
      } else {
        _animationController.value = 0;
      }
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isDark = !_isDark;
    });

    if (_isDark) {
      _animationController.forward();
      await _themeService.setThemeMode(ThemeMode.dark);
    } else {
      _animationController.reverse();
      await _themeService.setThemeMode(ThemeMode.light);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleTheme,
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: _isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 8,
              top: 8,
              child: AnimatedOpacity(
                opacity: _isDark ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.nightlight_round,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: AnimatedOpacity(
                opacity: _isDark ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.wb_sunny,
                  color: Color(0xFFFFD60A),
                  size: 24,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: 4 + (_animation.value * 36),
                  top: 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
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
