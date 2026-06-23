import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text('A propos', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo et nom
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray5),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.shopping_bag, color: AppColors.white, size: 44),
                ),
                const SizedBox(height: 16),
                const Text(
                  'EstuaireAchats',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 13, color: AppColors.gray3),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'EstuaireAchats - La plateforme e-commerce multi-vendeurs du Cameroun',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.gray2, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Liens utiles
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray5),
            ),
            child: Column(
              children: [
                _buildLinkTile(
                  icon: Icons.language,
                  title: 'Site web',
                  subtitle: 'www.estuaireachats.cm',
                  color: AppColors.blue,
                ),
                const Divider(height: 1, indent: 56),
                _buildLinkTile(
                  icon: Icons.email_outlined,
                  title: 'Contact',
                  subtitle: 'support@estuaireachats.cm',
                  color: AppColors.orange,
                ),
                const Divider(height: 1, indent: 56),
                _buildLinkTile(
                  icon: Icons.phone_outlined,
                  title: 'Telephone',
                  subtitle: '+237 6 XX XX XX XX',
                  color: AppColors.green,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray5),
            ),
            child: const Center(
              child: Text(
                '© 2026 EstuaireAchats. Tous droits reserves.',
                style: TextStyle(fontSize: 12, color: AppColors.gray3),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.gray4, size: 20),
    );
  }
}
