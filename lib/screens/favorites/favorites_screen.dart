import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/product_card.dart';
import '../shop/shop_screen.dart';
import '../main_screen.dart';
import '../auth/login_screen.dart';

MockProduct _productFromApi(Map<String, dynamic> p) {
  final images = p['images'] as List? ?? [];
  final mainImg = images.isNotEmpty
      ? (images.firstWhere((i) => i['isMain'] == true, orElse: () => images[0]))['url'] as String
      : 'https://placehold.co/400x400/eee/999?text=No+Image';
  final shop = p['shop'] as Map<String, dynamic>?;
  return MockProduct(
    id: p['id']?.toString() ?? '',
    name: p['name'] ?? '',
    image: mainImg,
    priceMin: (p['price'] as num?)?.toDouble() ?? 0,
    priceMax: (p['price'] as num?)?.toDouble() ?? 0,
    moq: (p['minOrderQty'] as num?)?.toInt() ?? 1,
    seller: shop?['name'] ?? '',
    origin: p['origin'] ?? 'CM',
    sellerYears: (shop?['yearsActive'] as num?)?.toInt() ?? 1,
    verified: shop?['verified'] == true,
    sold: (p['totalSold'] as num?)?.toInt() ?? 0,
    rating: (p['rating'] as num?)?.toDouble() ?? 0,
    reviews: (p['totalReviews'] as num?)?.toInt() ?? 0,
    category: '',
  );
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = true;
  String? _error;
  List<MockProduct> _products = [];
  List<Map<String, dynamic>> _suppliers = [];
  // Map productId -> wishlistItemId for removal
  Map<String, String> _productWishlistIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'auth';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService().get('/wishlists');
      final List data = res.data['data'] ?? [];
      final products = <MockProduct>[];
      final productWishlistIds = <String, String>{};
      final shopMap = <String, Map<String, dynamic>>{};

      for (final item in data) {
        final product = item['product'] as Map<String, dynamic>?;
        if (product == null) continue;
        final mp = _productFromApi(product);
        products.add(mp);
        productWishlistIds[mp.id] = item['id']?.toString() ?? '';

        final shop = product['shop'] as Map<String, dynamic>?;
        if (shop != null && shop['name'] != null) {
          shopMap[shop['name'] as String] = shop;
        }
      }

      final suppliers = shopMap.entries.map((e) {
        final s = e.value;
        return {
          'name': s['name'] ?? '',
          'id': s['id']?.toString() ?? '',
          'verified': s['verified'] == true,
          'yearsActive': (s['yearsActive'] as num?)?.toInt() ?? 1,
        };
      }).toList();

      setState(() {
        _products = products;
        _productWishlistIds = productWishlistIds;
        _suppliers = suppliers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Impossible de charger vos favoris';
      });
    }
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      await ApiService().delete('/wishlists/remove/$productId');
      setState(() {
        _products.removeWhere((p) => p.id == productId);
        _productWishlistIds.remove(productId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit retiré des favoris'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Mes favoris', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_products.length}',
                  style: const TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.gray3,
            indicatorColor: AppColors.orange,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Produits'),
              Tab(text: 'Fournisseurs'),
            ],
          ),
        ),
        body: _error == 'auth'
            ? _buildAuthRequired()
            : TabBarView(
                children: [
                  _buildProductsTab(context),
                  _buildSuppliersTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildAuthRequired() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 72, color: AppColors.gray4),
          const SizedBox(height: 16),
          const Text('Connectez-vous pour voir vos favoris', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray2)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }
    if (_error != null && _error != 'auth') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(fontSize: 14, color: AppColors.gray2)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return _buildEmptyState(context);
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.56,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) => ProductCard(product: _products[index]),
    );
  }

  Widget _buildSuppliersTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }
    if (_suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined, size: 72, color: AppColors.gray4),
            const SizedBox(height: 16),
            const Text('Aucun fournisseur suivi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray2)),
            const SizedBox(height: 8),
            const Text('Ajoutez des produits à vos favoris', style: TextStyle(fontSize: 13, color: AppColors.gray3)),
          ],
        ),
      );
    }
    final colors = [AppColors.orange, AppColors.green, AppColors.blue, const Color(0xFF9C27B0), AppColors.red];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suppliers.length,
      itemBuilder: (context, index) {
        final s = _suppliers[index];
        final name = s['name'] as String;
        final color = colors[index % colors.length];
        return Padding(
          padding: EdgeInsets.only(bottom: index < _suppliers.length - 1 ? 12 : 0),
          child: _SupplierCard(
            name: name,
            location: 'Cameroun',
            productCount: _products.where((p) => p.seller == name).length,
            initial: name.isNotEmpty ? name[0] : '?',
            color: color,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 72, color: AppColors.gray4),
          const SizedBox(height: 16),
          const Text('Aucun favori pour le moment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray2)),
          const SizedBox(height: 8),
          const Text('Ajoutez des produits à vos favoris', style: TextStyle(fontSize: 13, color: AppColors.gray3)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Explorez nos produits'),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final String name;
  final String location;
  final int productCount;
  final String initial;
  final Color color;

  const _SupplierCard({
    required this.name,
    required this.location,
    required this.productCount,
    required this.initial,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color,
            child: Text(initial, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: AppColors.gray3),
                    const SizedBox(width: 2),
                    Text(location, style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$productCount produits', style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShopScreen(shopName: name)),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Voir boutique', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
