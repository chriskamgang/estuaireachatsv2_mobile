import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _packages = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final response = await ApiService().get('/seller-packages');
      if (response.data is List) {
        setState(() {
          _packages = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback avec des packages par defaut si l'API n'est pas disponible
      setState(() {
        _packages = [
          {
            'name': 'Starter',
            'price': 0,
            'duration': 'Gratuit',
            'features': ['5 produits', 'Messagerie basique', 'Statistiques limitees'],
          },
          {
            'name': 'Business',
            'price': 15000,
            'duration': '/mois',
            'features': ['50 produits', 'Messagerie illimitee', 'Statistiques completes', 'Badge verifie'],
          },
          {
            'name': 'Premium',
            'price': 45000,
            'duration': '/mois',
            'features': ['Produits illimites', 'Messagerie prioritaire', 'Analytics avances', 'Badge Premium', 'Support dedie', 'Mise en avant'],
          },
        ];
        _isLoading = false;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnement', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.gray3),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.gray2)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadPackages, child: const Text('Reessayer')),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _packages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pkg = _packages[index];
                    final isPopular = index == 1;
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPopular ? AppColors.orange : AppColors.gray5,
                          width: isPopular ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (isPopular)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                              ),
                              child: const Text(
                                'Populaire',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pkg['name'] as String,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.dark),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      pkg['price'] == 0 ? 'Gratuit' : '${pkg['price']} FCFA',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: isPopular ? AppColors.orange : AppColors.dark,
                                      ),
                                    ),
                                    if (pkg['price'] != 0)
                                      Text(
                                        pkg['duration'] as String,
                                        style: const TextStyle(fontSize: 13, color: AppColors.gray3),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                ...((pkg['features'] as List).map((f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, size: 16, color: AppColors.green),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(f as String, style: const TextStyle(fontSize: 13, color: AppColors.gray1))),
                                        ],
                                      ),
                                    ))),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Abonnement ${pkg['name']} selectionne'),
                                          backgroundColor: AppColors.green,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPopular ? AppColors.orange : AppColors.gray6,
                                      foregroundColor: isPopular ? Colors.white : AppColors.dark,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      pkg['price'] == 0 ? 'Actuel' : 'S\'abonner',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
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
