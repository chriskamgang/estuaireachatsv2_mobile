import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/utils.dart';
import '../../data/mock_data.dart';
import '../../widgets/product_card.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<MockProduct> _products = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  late String _sort;

  final _sortOptions = const {
    'newest': 'Plus récents',
    'best_selling': 'Meilleures ventes',
    'price_asc': 'Prix croissant',
    'price_desc': 'Prix décroissant',
    'rating': 'Mieux notés',
  };

  @override
  void initState() {
    super.initState();
    _sort = widget.categoryId.isEmpty ? 'best_selling' : 'newest';
    _loadProducts();
  }

  Future<void> _loadProducts({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final params = <String, dynamic>{
        'perPage': 20,
        'page': page,
        'sort': _sort,
      };
      if (widget.categoryId.isNotEmpty) {
        params['categoryId'] = widget.categoryId;
      }
      final res = await ApiService().get('/products', params: params);

      final data = res.data['data'] as List? ?? [];
      final meta = res.data['meta'] as Map<String, dynamic>?;

      final products = data.map<MockProduct>((p) {
        final images = p['images'] as List? ?? [];
        final mainImg = images.isNotEmpty
            ? (images.firstWhere((i) => i['isMain'] == true, orElse: () => images[0]))['url'] as String
            : 'https://placehold.co/400x400/eee/999?text=No+Image';
        final shop = p['shop'] as Map<String, dynamic>?;

        return MockProduct(
          id: p['id']?.toString() ?? '',
          name: p['name'] ?? '',
          image: mainImg,
          priceMin: (p['priceMin'] as num?)?.toDouble() ?? (p['price'] as num?)?.toDouble() ?? 0,
          priceMax: (p['priceMax'] as num?)?.toDouble() ?? (p['price'] as num?)?.toDouble() ?? 0,
          moq: (p['minOrderQty'] as num?)?.toInt() ?? 1,
          seller: shop?['name'] ?? '',
          origin: p['origin'] ?? 'CM',
          sellerYears: (shop?['yearsActive'] as num?)?.toInt() ?? 1,
          verified: shop?['verified'] == true,
          sold: (p['totalSold'] as num?)?.toInt() ?? 0,
          rating: (p['rating'] as num?)?.toDouble() ?? 0,
          reviews: (p['totalReviews'] as num?)?.toInt() ?? 0,
          category: widget.categoryName,
        );
      }).toList();

      setState(() {
        _products = products;
        _page = page;
        _lastPage = (meta?['lastPage'] as num?)?.toInt() ?? 1;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Erreur de chargement';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sort bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  _loading ? 'Chargement...' : '${_products.length} produits',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray2),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _sort = value;
                    _loadProducts();
                  },
                  itemBuilder: (_) => _sortOptions.entries
                      .map((e) => PopupMenuItem(
                            value: e.key,
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _sort == e.key ? FontWeight.w700 : FontWeight.normal,
                                color: _sort == e.key ? AppColors.orange : AppColors.dark,
                              ),
                            ),
                          ))
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _sortOptions[_sort] ?? 'Trier',
                        style: const TextStyle(fontSize: 13, color: AppColors.orange, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.orange, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray5),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.gray3),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppColors.gray2)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.gray4),
                                const SizedBox(height: 12),
                                const Text(
                                  'Aucun produit dans cette catégorie',
                                  style: TextStyle(fontSize: 14, color: AppColors.gray2),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadProducts(page: 1),
                            color: AppColors.orange,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (_, i) => ProductCard(product: _products[i]),
                            ),
                          ),
          ),

          // Pagination
          if (!_loading && _products.isNotEmpty && _lastPage > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.gray5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1 ? () => _loadProducts(page: _page - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.orange,
                  ),
                  Text(
                    'Page $_page / $_lastPage',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: _page < _lastPage ? () => _loadProducts(page: _page + 1) : null,
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.orange,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
