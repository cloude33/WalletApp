import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isVerifying;

  const PinSetupScreen({super.key, this.isVerifying = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final AuthService _authService = AuthService();
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;

  void _onNumberPress(String number) {
    setState(() {
      if (!_isConfirming && !widget.isVerifying) {
        if (_pin.length < 4) {
          _pin += number;
          if (_pin.length == 4) {
            Future.delayed(const Duration(milliseconds: 200), () {
              setState(() {
                _isConfirming = true;
              });
            });
          }
        }
      } else if (_isConfirming) {
        if (_confirmPin.length < 4) {
          _confirmPin += number;
          if (_confirmPin.length == 4) {
            _verifyPin();
          }
        }
      } else if (widget.isVerifying) {
        if (_pin.length < 4) {
          _pin += number;
          if (_pin.length == 4) {
            _checkPin();
          }
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (!_isConfirming && !widget.isVerifying) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else if (widget.isVerifying) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyPin() async {
    if (_pin == _confirmPin) {
      await _authService.savePinCode(_pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN başarıyla kaydedildi'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN kodları eşleşmiyor'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
        setState(() {
          _pin = '';
          _confirmPin = '';
          _isConfirming = false;
        });
      }
    }
  }

  Future<void> _checkPin() async {
    final isValid = await _authService.verifyPinCode(_pin);
    if (isValid && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hatalı PIN kodu'),
          backgroundColor: Color(0xFFFF3B30),
        ),
      );
      setState(() {
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    String currentPin;

    if (widget.isVerifying) {
      title = 'PIN Girin';
      subtitle = 'Devam etmek için PIN kodunuzu girin';
      currentPin = _pin;
    } else if (_isConfirming) {
      title = 'PIN Onaylayın';
      subtitle = 'PIN kodunuzu tekrar girin';
      currentPin = _confirmPin;
    } else {
      title = 'PIN Oluşturun';
      subtitle = '4 haneli PIN kodunuzu oluşturun';
      currentPin = _pin;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF5E5CE6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < currentPin.length
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                );
              }),
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildNumberRow(['1', '2', '3']),
                  const SizedBox(height: 20),
                  _buildNumberRow(['4', '5', '6']),
                  const SizedBox(height: 20),
                  _buildNumberRow(['7', '8', '9']),
                  const SizedBox(height: 20),
                  _buildBottomRow(),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumberButton(number)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 80, height: 80),
        _buildNumberButton('0'),
        _buildBackspaceButton(),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberPress(number),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
