import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  // Code de parrainage statique (a remplacer par API plus tard)
  static const String _referralCode = 'EA-2024-XXXX';

  void _copyCode(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copie dans le presse-papiers'),
        backgroundColor: AppColors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCode(BuildContext context) {
    // Pour l'instant, copier le code
    Clipboard.setData(const ClipboardData(
      text: 'Rejoignez EstuaireAchats avec mon code de parrainage : $_referralCode et gagnez 5 000 FCFA de credits !',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien de parrainage copie'),
        backgroundColor: AppColors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text(
          'Parrainage',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8C00), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.white, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Parrainez vos amis',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gagnez 5 000 FCFA pour chaque ami\nqui passe sa premiere commande',
                    style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Code de parrainage
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Votre code de parrainage',
                      style: TextStyle(fontSize: 13, color: AppColors.gray2),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.gray6,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            _referralCode,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                              letterSpacing: 2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _copyCode(context),
                            child: const Icon(Icons.copy, color: AppColors.primary, size: 22),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _shareCode(context),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Partager mon code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Comment ca marche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comment ca marche ?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                    const SizedBox(height: 16),
                    _StepItem(
                      number: '1',
                      title: 'Partagez votre code',
                      subtitle: 'Envoyez votre code de parrainage a vos amis via WhatsApp, SMS ou reseaux sociaux',
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      number: '2',
                      title: 'Votre ami s\'inscrit',
                      subtitle: 'Votre ami cree un compte et saisit votre code lors de son inscription',
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      number: '3',
                      title: 'Vous gagnez tous les deux',
                      subtitle: 'Votre ami recoit 2 000 FCFA et vous recevez 5 000 FCFA apres sa premiere commande',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _StepItem({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.gray2, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
