import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final certificates = [
      {
        'name': 'Acheteur verifie',
        'icon': Icons.verified_user,
        'color': AppColors.green,
        'date': '15 Jan 2026',
        'status': 'Actif',
        'description': 'Votre identite a ete verifiee avec succes.',
      },
      {
        'name': 'Badge premium',
        'icon': Icons.workspace_premium,
        'color': AppColors.orange,
        'date': null,
        'status': 'Non obtenu',
        'description': 'Souscrivez a un abonnement Premium pour obtenir ce badge.',
      },
      {
        'name': 'Acheteur fidele',
        'icon': Icons.loyalty,
        'color': AppColors.secondary,
        'date': null,
        'status': 'Non obtenu',
        'description': 'Effectuez 10 commandes pour debloquer ce certificat.',
      },
      {
        'name': 'Certificat entreprise',
        'icon': Icons.business,
        'color': AppColors.dark,
        'date': null,
        'status': 'Non soumis',
        'description': 'Soumettez vos documents d\'entreprise pour la verification.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificats & Badges', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: certificates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cert = certificates[index];
          final isActive = cert['status'] == 'Actif';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? (cert['color'] as Color).withOpacity(0.3) : AppColors.gray5),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (cert['color'] as Color).withOpacity(isActive ? 0.1 : 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    cert['icon'] as IconData,
                    color: isActive ? cert['color'] as Color : AppColors.gray4,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cert['name'] as String,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.green.withOpacity(0.1) : AppColors.gray6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              cert['status'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive ? AppColors.green : AppColors.gray3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cert['description'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.gray2),
                      ),
                      if (cert['date'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Obtenu le ${cert['date']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.gray3),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
