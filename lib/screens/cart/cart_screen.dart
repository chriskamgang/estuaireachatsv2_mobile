import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/mock_data.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../checkout/checkout_screen.dart';
import '../favorites/favorites_screen.dart';
import '../search/search_screen.dart';

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

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('Panier(${cart.itemCount})', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(width: 8),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray3),
                    Text(' Livraison CM', style: TextStyle(fontSize: 11, color: AppColors.gray3)),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    ),
                    child: Icon(Icons.favorite_border, color: AppColors.gray3),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty ? _EmptyCart() : _FilledCart(cart: cart),
            ),
            // Bottom bar
            Container(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => cart.toggleAll(cart.items.any((i) => !i.selected)),
                      child: Icon(
                        cart.items.every((i) => i.selected) ? Icons.check_circle : Icons.circle_outlined,
                        color: cart.items.every((i) => i.selected) ? AppColors.orange : AppColors.gray4,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Tous', style: TextStyle(fontSize: 13)),
                  ]),
                  const Spacer(),
                  Text(formatPrice(cart.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.gray3),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: cart.isEmpty ? null : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Payer', style: TextStyle(fontWeight: FontWeight.w700)),
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

class _EmptyCart extends StatefulWidget {
  @override
  State<_EmptyCart> createState() => _EmptyCartState();
}

class _EmptyCartState extends State<_EmptyCart> {
  bool _loadingRecommended = true;
  List<MockProduct> _recommendedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadRecommended();
  }

  Future<void> _loadRecommended() async {
    try {
      final res = await ApiService().get('/products/featured');
      final List data = res.data['data'] ?? [];
      final products = data.take(6).map<MockProduct>((p) => _productFromApi(p as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _recommendedProducts = products;
          _loadingRecommended = false;
        });
      }
    } catch (_) {
      // Fallback to empty on error
      if (mounted) {
        setState(() => _loadingRecommended = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 40),
        Center(child: Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.gray4)),
        const SizedBox(height: 12),
        const Center(child: Text('Votre panier est vide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark))),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Explorer par catégories'),
          ),
        ),
        const SizedBox(height: 24),
        // Protection section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.gray5), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Protection des commandes EstuaireAchats', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.gray3),
                ],
              ),
              const SizedBox(height: 10),
              _ProtectionItem(icon: Icons.verified_user, text: 'Paiements sécurisés', badges: ['VISA', 'MC', 'MoMo', 'OM', 'PayPal']),
              const SizedBox(height: 6),
              _ProtectionItem(icon: Icons.local_shipping, text: 'Livraison garantie', badges: []),
              const SizedBox(height: 6),
              _ProtectionItem(icon: Icons.shield, text: 'Protection et remboursement', badges: []),
              const SizedBox(height: 8),
              Text('Seules les commandes passées et payées via EstuaireAchats sont protégées', style: TextStyle(fontSize: 10, color: AppColors.gray3)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Recommandes pour vous', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        const SizedBox(height: 8),
        if (_loadingRecommended)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
          )
        else if (_recommendedProducts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _recommendedProducts.length,
              itemBuilder: (_, i) => ProductCard(product: _recommendedProducts[i]),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _FilledCart extends StatelessWidget {
  final CartProvider cart;
  const _FilledCart({required this.cart});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cart.items.length,
      itemBuilder: (_, i) {
        final item = cart.items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => cart.toggleSelection(item.id),
                child: Icon(
                  item.selected ? Icons.check_circle : Icons.circle_outlined,
                  color: item.selected ? AppColors.orange : AppColors.gray4,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(item.image, width: 60, height: 60, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppColors.gray5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(formatPrice(item.price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => item.quantity > 1 ? cart.updateQuantity(item.id, item.quantity - 1) : null,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.gray4), borderRadius: BorderRadius.circular(4)),
                            child: const Icon(Icons.remove, size: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        GestureDetector(
                          onTap: () => cart.updateQuantity(item.id, item.quantity + 1),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.gray4), borderRadius: BorderRadius.circular(4)),
                            child: const Icon(Icons.add, size: 14),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => cart.removeItem(item.id),
                          child: const Icon(Icons.delete_outline, size: 18, color: AppColors.gray3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProtectionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final List<String> badges;
  const _ProtectionItem({required this.icon, required this.text, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.green),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        ...badges.map((b) => Container(
          margin: const EdgeInsets.only(left: 3),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: AppColors.gray5, borderRadius: BorderRadius.circular(2)),
          child: Text(b, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700)),
        )),
      ],
    );
  }
}
