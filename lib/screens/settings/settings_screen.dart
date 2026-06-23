import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'legal_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _promoEmails = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        children: [
          // Compte
          _buildSectionHeader('Compte'),
          _buildTile(
            icon: Icons.person_outline,
            title: 'Informations personnelles',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _buildTile(
            icon: Icons.lock_outline,
            title: 'Changer mot de passe',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
          _buildTile(
            icon: Icons.email_outlined,
            title: 'Verification email',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Un email de verification a ete envoye')),
              );
            },
          ),
          const Divider(height: 1),

          // Preferences
          _buildSectionHeader('Preferences'),
          _buildTile(
            icon: Icons.language,
            title: 'Langue',
            trailing: 'Francais',
            onTap: () => _showLanguageSheet(context),
          ),
          _buildTile(
            icon: Icons.currency_exchange,
            title: 'Devise',
            trailing: 'FCFA',
            onTap: () => _showCurrencySheet(context),
          ),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications push',
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          _buildSwitchTile(
            icon: Icons.mark_email_read_outlined,
            title: 'Emails promotionnels',
            value: _promoEmails,
            onChanged: (v) => setState(() => _promoEmails = v),
          ),
          const Divider(height: 1),

          // A propos
          _buildSectionHeader('A propos'),
          _buildTile(
            icon: Icons.info_outline,
            title: 'A propos',
            trailing: '1.0.0',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          _buildTile(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LegalScreen(
                  title: 'Conditions d\'utilisation',
                  content: 'En utilisant EstuaireAchats, vous acceptez les presentes conditions d\'utilisation.\n\n'
                      '1. Utilisation de la plateforme\nEstuaireAchats est une plateforme e-commerce multi-vendeurs destinee aux particuliers et professionnels souhaitant acheter ou vendre des produits au Cameroun et en Afrique centrale.\n\n'
                      '2. Compte utilisateur\nVous etes responsable de la confidentialite de votre mot de passe et de toutes les activites effectuees depuis votre compte.\n\n'
                      '3. Transactions\nToutes les transactions sont effectuees entre acheteurs et vendeurs. EstuaireAchats sert d\'intermediaire et ne peut etre tenu responsable des litiges entre parties.\n\n'
                      '4. Protection des donnees\nVos donnees personnelles sont traitees conformement a notre politique de confidentialite.\n\n'
                      '5. Modifications\nNous nous reservons le droit de modifier ces conditions a tout moment. Les modifications seront notifiees par email.\n\n'
                      'Pour toute question : support@estuaireachats.cm',
                ),
              ),
            ),
          ),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialite',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LegalScreen(
                  title: 'Politique de confidentialite',
                  content: 'EstuaireAchats s\'engage a proteger votre vie privee.\n\n'
                      '1. Donnees collectees\nNous collectons les informations que vous nous fournissez lors de la creation de votre compte : nom, email, numero de telephone, adresses de livraison.\n\n'
                      '2. Utilisation des donnees\nVos donnees sont utilisees pour :\n- Traiter vos commandes\n- Vous envoyer des notifications de livraison\n- Ameliorer nos services\n- Vous contacter en cas de probleme\n\n'
                      '3. Partage des donnees\nNous ne vendons jamais vos donnees a des tiers. Vos informations peuvent etre partagees avec les vendeurs uniquement dans le cadre d\'une commande.\n\n'
                      '4. Securite\nNos serveurs sont proteges par un chiffrement SSL 256 bits. Vos mots de passe sont hashs et ne sont jamais stockes en clair.\n\n'
                      '5. Vos droits\nVous pouvez demander la suppression de vos donnees a tout moment via les parametres de l\'application ou en nous contactant a privacy@estuaireachats.cm',
                ),
              ),
            ),
          ),
          _buildTile(
            icon: Icons.source_outlined,
            title: 'Licences open source',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LegalScreen(
                  title: 'Licences open source',
                  content: 'Cette application utilise les bibliotheques open source suivantes :\n\n'
                      '- Flutter (BSD License) - Google LLC\n'
                      '- Dio (MIT License)\n'
                      '- Provider (MIT License)\n'
                      '- Cached Network Image (MIT License)\n'
                      '- Flutter Local Notifications (MIT License)\n\n'
                      'Les licences completes sont disponibles dans le depot source de l\'application.',
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // Danger zone
          _buildSectionHeader('Danger zone'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.red, size: 22),
            title: const Text('Supprimer mon compte', style: TextStyle(fontSize: 14, color: AppColors.red)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.gray4, size: 20),
            dense: true,
            onTap: () => _showDeleteAccountDialog(context),
          ),
          const Divider(height: 1),

          // Deconnexion
          if (auth.isAuthenticated) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    auth.logout();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Se deconnecter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray3, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gray2, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(trailing, style: const TextStyle(fontSize: 13, color: AppColors.gray3)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.gray4, size: 20),
              ],
            )
          : const Icon(Icons.chevron_right, color: AppColors.gray4, size: 20),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gray2, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.orange,
      ),
      dense: true,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Supprimer votre compte ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          'Cette action est irreversible. Toutes vos donnees, commandes et favoris seront definitivement supprimes.',
          style: TextStyle(fontSize: 14, color: AppColors.gray2, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppColors.gray2)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ApiService();
                await api.delete('/users/me');
                if (context.mounted) {
                  await context.read<AuthProvider>().logout();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: AppColors.red),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    String selected = 'fr';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray4, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                const Text('Choisir une langue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _buildSheetOption(
                  label: 'Francais',
                  value: 'fr',
                  groupValue: selected,
                  onChanged: (v) => setSheetState(() => selected = v!),
                ),
                _buildSheetOption(
                  label: 'English',
                  value: 'en',
                  groupValue: selected,
                  onChanged: (v) => setSheetState(() => selected = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCurrencySheet(BuildContext context) {
    String selected = 'XAF';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray4, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                const Text('Choisir une devise', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _buildSheetOption(
                  label: 'Franc CFA (FCFA / XAF)',
                  value: 'XAF',
                  groupValue: selected,
                  onChanged: (v) => setSheetState(() => selected = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      activeColor: AppColors.orange,
      contentPadding: EdgeInsets.zero,
    );
  }
}
