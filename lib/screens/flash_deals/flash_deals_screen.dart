import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class FlashDealsScreen extends StatefulWidget {
  const FlashDealsScreen({super.key});

  @override
  State<FlashDealsScreen> createState() => _FlashDealsScreenState();
}

class _FlashDealsScreenState extends State<FlashDealsScreen> {
  final _api = ApiService();
  List<dynamic> _deals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/flash-deals');
      setState(() {
        _deals = (res.data is List) ? res.data as List<dynamic> : (res.data['data'] as List<dynamic>? ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Impossible de charger les ventes flash'; _loading = false; });
    }
  }

  int _discountPercent(dynamic product) {
    final original = (product['originalPrice'] as num?)?.toDouble() ?? 0;
    final current = (product['price'] as num?)?.toDouble() ?? 0;
    if (original <= 0 || current <= 0) return 0;
    return (((original - current) / original) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            const Text(
              'Ventes Flash',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.gray4),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.gray2)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadDeals, child: const Text('Reessayer')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadDeals,
                  child: _deals.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flash_off, size: 72, color: AppColors.gray4),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Aucun flash deal actif',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Revenez bientot pour decouvrir\ndes offres exclusives a prix reduit',
                                    style: TextStyle(fontSize: 14, color: AppColors.gray3),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: _deals.length,
                          itemBuilder: (context, index) {
                            final deal = _deals[index] as Map<String, dynamic>;
                            final discount = _discountPercent(deal);
                            final price = (deal['price'] as num?)?.toDouble() ?? 0;
                            final originalPrice = (deal['originalPrice'] as num?)?.toDouble() ?? 0;
                            final imageUrl = (deal['images'] as List?)?.isNotEmpty == true
                                ? deal['images'][0] as String?
                                : null;

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                        child: imageUrl != null
                                            ? Image.network(
                                                imageUrl,
                                                height: 140,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  height: 140,
                                                  color: AppColors.gray6,
                                                  child: const Icon(Icons.image_not_supported, color: AppColors.gray4, size: 40),
                                                ),
                                              )
                                            : Container(
                                                height: 140,
                                                color: AppColors.gray6,
                                                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.gray4, size: 40),
                                              ),
                                      ),
                                      if (discount > 0)
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '-$discount%',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  // Infos
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deal['name'] as String? ?? 'Produit',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: AppColors.gray1, height: 1.3),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          formatPrice(price),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (originalPrice > 0 && originalPrice > price)
                                          Text(
                                            formatPrice(originalPrice),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.gray3,
                                              decoration: TextDecoration.lineThrough,
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
                ),
    );
  }
}
