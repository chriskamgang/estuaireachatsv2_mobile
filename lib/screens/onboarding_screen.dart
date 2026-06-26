import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.public,
      color: AppColors.orange,
      title: 'Achetez partout en Afrique',
      description: 'Commandez depuis la Chine, l\'Europe ou en local. Livraison au Cameroun, Cote d\'Ivoire, Gabon, Senegal et dans 16 pays africains.',
    ),
    _OnboardingPage(
      icon: Icons.phone_android,
      color: AppColors.green,
      title: 'Payez avec Mobile Money',
      description: 'MTN MoMo, Orange Money, et bien plus. Paiements securises en FCFA directement depuis votre telephone.',
    ),
    _OnboardingPage(
      icon: Icons.local_shipping,
      color: AppColors.blue,
      title: 'Livraison garantie',
      description: 'Suivi en temps reel de vos colis. Protection de remboursement pendant 60 jours sur toutes vos commandes.',
    ),
    _OnboardingPage(
      icon: Icons.verified,
      color: AppColors.red,
      title: 'Fournisseurs verifies',
      description: 'Des milliers de fournisseurs verifies. Qualite garantie, prix d\'usine, commande minimum flexible.',
    ),
  ];

  void _goToMain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _goToMain,
                child: const Text('Passer', style: TextStyle(color: AppColors.gray3)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_pages.length, (i) => Container(
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _currentPage == i ? AppColors.orange : AppColors.gray4,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  if (_currentPage == _pages.length - 1)
                    ElevatedButton(
                      onPressed: _goToMain,
                      child: const Text('Commencer'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: const Text('Suivant'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: color),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.gray2,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
