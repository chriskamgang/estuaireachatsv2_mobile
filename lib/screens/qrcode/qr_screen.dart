import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class QrScreen extends StatelessWidget {
  const QrScreen({super.key});

  static const String _referralCode = 'EA-2024-XXXX';
  static const String _qrData = 'https://estuaireachats.com/referral/$_referralCode';

  @override
  Widget build(BuildContext context) {
    // Utilise une API gratuite pour generer le QR code en image
    final qrImageUrl = Uri.encodeFull(
      'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=$_qrData',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon QR Code', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'EstuaireAchats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Scannez pour me parrainer',
                      style: TextStyle(fontSize: 13, color: AppColors.gray3),
                    ),
                    const SizedBox(height: 20),
                    Image.network(
                      qrImageUrl,
                      width: 220,
                      height: 220,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: AppColors.gray6,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2, size: 80, color: AppColors.gray3),
                              SizedBox(height: 8),
                              Text('QR Code', style: TextStyle(color: AppColors.gray3)),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.gray6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            _referralCode,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(const ClipboardData(text: _referralCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code copie dans le presse-papiers'),
                                  backgroundColor: AppColors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Icon(Icons.copy, size: 20, color: AppColors.orange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Partagez ce QR code avec vos amis pour\nles parrainer et gagner des coupons',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.gray2, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
