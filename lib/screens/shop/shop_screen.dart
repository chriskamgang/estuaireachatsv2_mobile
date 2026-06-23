import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/product_card.dart';
import '../cart/cart_screen.dart';
import '../messaging/chat_screen.dart';

class ShopScreen extends StatefulWidget {
  final String shopName;
  final String? shopSlug;

  const ShopScreen({super.key, required this.shopName, this.shopSlug});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _shopData = {};
  List<MockProduct> _shopProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      Map<String, dynamic> data;

      if (widget.shopSlug != null && widget.shopSlug!.isNotEmpty) {
        final res = await ApiService().get('/shops/${widget.shopSlug}');
        data = res.data as Map<String, dynamic>;
      } else {
        // Fallback: search by name
        final res = await ApiService().get('/shops', params: {'search': widget.shopName});
        final results = res.data;
        final List list = results is Map ? (results['data'] as List? ?? []) : (results as List? ?? []);
        if (list.isEmpty) {
          throw Exception('Boutique introuvable');
        }
        data = list[0] as Map<String, dynamic>;
      }

      // Map API data to _shopData structure used by UI
      _shopData = {
        'name': data['name'] ?? widget.shopName,
        'slug': data['slug'] ?? '',
        'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
        'totalReviews': (data['totalReviews'] as num?)?.toInt() ?? 0,
        'years': (data['yearsActive'] as num?)?.toInt() ?? 0,
        'location': data['address'] ?? '',
        'country': data['country'] ?? 'CM',
        'flag': data['country'] ?? 'CM',
        'verified': data['verified'] == true,
        'logo': data['logo'],
        'banner': data['banner'],
        'description': data['description'] ?? '',
        'customType': 'Fabricant sur mesure',
        'mainProduct': '',
        'leaderRank': '',
        'rebuyRate': 18,
        'staff': '',
        'area': '',
        'exportYears': (data['yearsActive'] as num?)?.toInt() ?? 0,
        'productionLines': 0,
        'annualOutput': '',
        'registrationDate': '',
        'customOptions': <String>[
          'Personnalisation simple',
          'Traitement échantillons',
        ],
        'mainMarkets': <Map<String, String>>[],
        'certifications': <String>['ISO 9001', 'CE'],
        'supplierService': (data['rating'] as num?)?.toDouble() ?? 4.5,
        'onTimeShipment': 5.0,
        'productQuality': (data['rating'] as num?)?.toDouble() ?? 4.5,
        'totalSales': '',
        'totalTransactions': '',
        'capabilities': <String>[
          'Personnalisation simple',
          'Personnalisation à partir de modèles',
        ],
        'reviews': <Map<String, dynamic>>[],
        'totalProducts': (data['meta']?['totalProducts'] as num?)?.toInt() ?? 0,
      };

      // Map products
      final apiProducts = data['products'] as List? ?? [];
      _shopProducts = apiProducts.map<MockProduct>((p) => _productFromApi(p)).toList();

      setState(() { _isLoading = false; });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur de chargement de la boutique';
      });
    }
  }

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
      seller: shop?['name'] ?? _shopData['name'] ?? '',
      origin: p['origin'] ?? 'CM',
      sellerYears: (shop?['yearsActive'] as num?)?.toInt() ?? (_shopData['years'] as int? ?? 1),
      verified: shop?['verified'] == true || _shopData['verified'] == true,
      sold: (p['totalSold'] as num?)?.toInt() ?? 0,
      rating: (p['rating'] as num?)?.toDouble() ?? 0,
      reviews: (p['totalReviews'] as num?)?.toInt() ?? 0,
      category: '',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.dark,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.dark,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.gray2, fontSize: 15)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadShopData,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                child: const Text('Reessayer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          // Custom app bar with search
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.dark,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: _buildSearchBar(),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 22),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien copié dans le presse-papiers'), duration: Duration(seconds: 2)),
                ),
              ),
            ],
          ),
          // Shop info header
          SliverToBoxAdapter(child: _buildShopHeader()),
          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.dark,
                unselectedLabelColor: AppColors.gray3,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: 'Accueil'),
                  Tab(text: 'Produits'),
                  Tab(text: 'Profil de l\'entreprise'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildHomeTab(),
            _buildProductsTab(),
            _buildCompanyProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.gray6,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Cette boutique', style: TextStyle(fontSize: 12, color: AppColors.dark, fontWeight: FontWeight.w500)),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.gray3),
              ],
            ),
          ),
          Container(width: 1, height: 20, color: AppColors.gray4),
          Expanded(
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Rechercher...', style: TextStyle(fontSize: 13, color: AppColors.gray3)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.gray2),
          ),
        ],
      ),
    );
  }

  Widget _buildShopHeader() {
    final shopName = _shopData['name'] ?? widget.shopName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verified badge + custom type
          if (_shopData['verified'] == true)
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ).createShader(bounds),
                  child: const Text(
                    'Vérifié',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _shopData['customType'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray2),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.info_outline, size: 14, color: AppColors.gray3),
              ],
            ),
          const SizedBox(height: 6),
          // Shop name + heart + chat button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  shopName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark, height: 1.2),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _isFavorite = !_isFavorite),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? AppColors.primary : AppColors.gray3,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      contactName: shopName,
                      company: shopName,
                      conversationId: '',
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Discuter maintenant',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Rating + years + location
          Row(
            children: [
              Text(
                '${_shopData['rating']}/5',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
              ),
              const SizedBox(width: 6),
              const Text('\u00B7', style: TextStyle(color: AppColors.gray3)),
              const SizedBox(width: 6),
              Text(
                '${_shopData['years']} ans',
                style: const TextStyle(fontSize: 13, color: AppColors.gray2),
              ),
              const SizedBox(width: 6),
              const Text('\u00B7', style: TextStyle(color: AppColors.gray3)),
              const SizedBox(width: 6),
              Text(
                '${_shopData['location']},',
                style: const TextStyle(fontSize: 13, color: AppColors.gray2),
              ),
              const SizedBox(width: 4),
              Image.network(
                'https://flagcdn.com/w20/${(_shopData['country'] as String).toLowerCase()}.png',
                width: 18,
                height: 13,
                errorBuilder: (_, __, ___) => Text(
                  _shopData['country'] ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _shopData['country'] ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.gray2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HOME TAB ---
  Widget _buildHomeTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Factory hero image
        Container(
          height: 220,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _shopData['banner'] ?? 'https://placehold.co/600x300/2C3E50/FFFFFF?text=Showroom+Usine',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2C3E50),
                  child: const Center(child: Text('Showroom', style: TextStyle(color: AppColors.white, fontSize: 24))),
                ),
              ),
              // Verified overlay top-left
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('EstuaireAchats', style: TextStyle(color: AppColors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                    if (_shopData['verified'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Fournisseur vérifié', style: TextStyle(color: AppColors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              // Bottom row: 360, video, photos
              Positioned(
                bottom: 12,
                left: 12,
                child: Row(
                  children: [
                    _iconBadge('360\u00B0'),
                    const SizedBox(width: 6),
                    _iconBadge('\u25B6'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 14, color: AppColors.white),
                          const SizedBox(width: 4),
                          Text('${_shopData['totalProducts'] ?? _shopProducts.length}', style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main products
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              const Text('PRODUITS PRINCIPAUX:  ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark)),
              Expanded(
                child: Text(
                  _shopData['mainProduct'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Leader rank
        if ((_shopData['leaderRank'] ?? '').toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _shopData['leaderRank'] ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.gray3),
              ],
            ),
          ),

        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.gray5),

        // Rating section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_shopData['rating']}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.dark, height: 1),
              ),
              const Text(
                '/5',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray3, height: 1.8),
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                final rating = (_shopData['rating'] as num).toDouble();
                return Icon(
                  i < rating.floor() ? Icons.star : (i < rating.ceil() ? Icons.star_half : Icons.star_border),
                  color: Colors.amber,
                  size: 18,
                );
              }),
              const SizedBox(width: 6),
              Text(
                '${_shopData['totalReviews'] ?? 0} avis',
                style: const TextStyle(fontSize: 13, color: AppColors.gray3, decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),

        // Rebuy rate
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            '${_shopData['rebuyRate']}% Taux de rachat',
            style: const TextStyle(fontSize: 13, color: AppColors.gray2),
          ),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.gray5),

        // Transaction history
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Historique des transactions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark),
              ),
              const SizedBox(height: 12),
              const Text('Tendances des commandes', style: TextStyle(fontSize: 13, color: AppColors.gray3)),
              const SizedBox(height: 8),
              // Mini chart placeholder
              Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomPaint(
                  size: const Size(double.infinity, 50),
                  painter: _MiniChartPainter(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Ventes', style: TextStyle(fontSize: 13, color: AppColors.gray3)),
              const SizedBox(height: 2),
              Text(
                '${_shopData['totalSales']} de ${_shopData['totalTransactions']} transactions',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Divider(height: 8, thickness: 8, color: AppColors.gray6),

        // Supplier capabilities
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Capacités des fournisseurs',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark),
              ),
              const SizedBox(height: 4),
              const Text('Vérifié par SGS', style: TextStyle(fontSize: 12, color: AppColors.gray3, decoration: TextDecoration.underline)),
              const SizedBox(height: 12),
              ...(_shopData['capabilities'] as List).map<Widget>((cap) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Text(cap, style: const TextStyle(fontSize: 14, color: AppColors.dark)),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rapport de vérification non disponible'), duration: Duration(seconds: 2)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gray4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Voir le rapport pour plus de détails', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark)),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 8, thickness: 8, color: AppColors.gray6),

        // All products preview
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tous les produits', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Row(
                      children: const [
                        Text('Tout afficher', style: TextStyle(fontSize: 13, color: AppColors.gray3)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.gray3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Product category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _productChip('Produit principal', true),
                    _productChip('Meilleure vente', true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 3x3 product grid preview
              _shopProducts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Aucun produit', style: TextStyle(color: AppColors.gray3))),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _shopProducts.length > 9 ? 9 : _shopProducts.length,
                      itemBuilder: (context, index) {
                        final p = _shopProducts[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.gray6,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    p.image,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, color: AppColors.gray4)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.dark, height: 1.3),
                            ),
                          ],
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _productChip(String label, bool highlight) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
          color: highlight ? AppColors.primary : AppColors.gray2,
        ),
      ),
    );
  }

  // --- PRODUCTS TAB ---
  Widget _buildProductsTab() {
    if (_shopProducts.isEmpty) {
      return const Center(child: Text('Aucun produit', style: TextStyle(color: AppColors.gray3)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.56,
      ),
      itemCount: _shopProducts.length,
      itemBuilder: (context, index) => ProductCard(product: _shopProducts[index]),
    );
  }

  // --- COMPANY PROFILE TAB ---
  Widget _buildCompanyProfileTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Verified overview card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE0C0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ).createShader(bounds),
                    child: const Text(
                      'Vérifié',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Apercu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(width: 6),
                  const Icon(Icons.info_outline, size: 16, color: AppColors.gray3),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Toutes les informations ci-dessous ont été vérifiées.',
                style: TextStyle(fontSize: 13, color: AppColors.gray2),
              ),
              const SizedBox(height: 16),
              const Text('Apercu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 12),
              if ((_shopData['registrationDate'] ?? '').toString().isNotEmpty)
                _profileRow('Date d\'enregistrement\nde la société', _shopData['registrationDate'] ?? ''),
              if ((_shopData['area'] ?? '').toString().isNotEmpty)
                _profileRow('Surface au sol (m\u00B2)', _shopData['area'] ?? ''),
              _profileRow('Années d\'exportation', '${_shopData['exportYears']}'),
              if ((_shopData['customOptions'] as List).isNotEmpty)
                _profileRow(
                  'Options de\npersonnalisation',
                  (_shopData['customOptions'] as List).join('\n'),
                ),
              if ((_shopData['mainMarkets'] as List).isNotEmpty)
                _profileRow(
                  'Marches\nprincipaux',
                  (_shopData['mainMarkets'] as List).map((m) => '${m['name']}(${m['percent']})').join('\n'),
                ),
              _profileRow('Années dans\nl\'industrie', '${_shopData['exportYears']}'),
              if ((_shopData['productionLines'] as num?) != null && (_shopData['productionLines'] as num) > 0)
                _profileRow('Lignes de\nproduction', '${_shopData['productionLines']}'),
              if ((_shopData['annualOutput'] ?? '').toString().isNotEmpty)
                _profileRow('Production\nannuelle totale\n(unites)', _shopData['annualOutput'] ?? ''),
            ],
          ),
        ),

        // Show more button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Toutes les informations sont affichées'), duration: Duration(seconds: 2)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gray4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Afficher plus', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark)),
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Divider(height: 8, thickness: 8, color: AppColors.gray6),

        // Certifications
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Certification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (_shopData['certifications'] as List).length,
                  itemBuilder: (context, i) {
                    final cert = (_shopData['certifications'] as List)[i];
                    return Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.gray6,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gray5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium, size: 28, color: AppColors.gray3),
                          const SizedBox(height: 6),
                          Text(cert, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.dark)),
                          const Text('Certificat', style: TextStyle(fontSize: 10, color: AppColors.gray3)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 8, thickness: 8, color: AppColors.gray6),

        // Profil TrustPass
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Profil TrustPass', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  Icon(Icons.chevron_right, color: AppColors.gray3),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _shopData['description']?.toString().isNotEmpty == true
                    ? _shopData['description']
                    : 'Les locaux de l\'entreprise du fournisseur ont été vérifiés par le personnel d\'EstuaireAchats pour s\'assurer de l\'existence des opérations sur place. Une société de vérification tierce a confirmé l\'existence légale du fournisseur.',
                style: const TextStyle(fontSize: 13, color: AppColors.gray2, height: 1.5),
              ),
              const SizedBox(height: 4),
              const Text('En savoir plus', style: TextStyle(fontSize: 13, color: AppColors.dark, decoration: TextDecoration.underline, fontWeight: FontWeight.w500)),
            ],
          ),
        ),

        const Divider(height: 8, thickness: 8, color: AppColors.gray6),

        // Company reviews
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Avis sur l\'entreprise', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  Icon(Icons.chevron_right, color: AppColors.gray3),
                ],
              ),
              const SizedBox(height: 14),
              // Big rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_shopData['rating']}',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.dark, height: 1),
                  ),
                  const Text('/5', style: TextStyle(fontSize: 16, color: AppColors.gray3, height: 2)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Satisfait', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
                      Text(
                        '${_shopData['totalReviews'] ?? 0} avis',
                        style: const TextStyle(fontSize: 13, color: AppColors.dark, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Rating bars
              _ratingBar('Service fournisseur', _shopData['supplierService']),
              const SizedBox(height: 10),
              _ratingBar('Expédition ponctuelle', _shopData['onTimeShipment']),
              const SizedBox(height: 10),
              _ratingBar('Qualité produit', _shopData['productQuality']),
              const SizedBox(height: 16),
              const Divider(color: AppColors.gray5),
              // Reviews list
              ...(_shopData['reviews'] as List).map<Widget>((review) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review['user'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                        const SizedBox(width: 6),
                        Image.network(
                          'https://flagcdn.com/w20/${review['countryCode']}.png',
                          width: 18,
                          height: 13,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(review['date'], style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                    const SizedBox(height: 4),
                    Text(review['comment'], style: const TextStyle(fontSize: 14, color: AppColors.dark)),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.gray5),
                  ],
                ),
              )),
            ],
          ),
        ),

        const Divider(height: 8, thickness: 8, color: AppColors.gray6),

        // Credits video et images
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Credits video et images', style: TextStyle(fontSize: 14, color: AppColors.gray2)),
              Icon(Icons.chevron_right, size: 18, color: AppColors.gray3),
            ],
          ),
        ),

        const Divider(height: 8, thickness: 8, color: AppColors.gray6),

        // All products
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tous les produits', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Row(
                      children: const [
                        Text('Tout afficher', style: TextStyle(fontSize: 13, color: AppColors.gray3)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.gray3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _shopProducts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Aucun produit', style: TextStyle(color: AppColors.gray3))),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _shopProducts.length > 12 ? 12 : _shopProducts.length,
                      itemBuilder: (context, index) {
                        final p = _shopProducts[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.gray6,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    p.image,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, color: AppColors.gray4)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.dark, height: 1.3),
                            ),
                          ],
                        );
                      },
                    ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray3, height: 1.4)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, height: 1.4),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(String label, dynamic score) {
    final value = (score as num).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray2)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 5.0,
              minHeight: 8,
              backgroundColor: AppColors.gray5,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final shopName = _shopData['name'] ?? widget.shopName;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray5)),
      ),
      child: Row(
        children: [
          // Categories button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.list_alt, size: 22, color: AppColors.gray2),
              SizedBox(height: 2),
              Text('Catégories', style: TextStyle(fontSize: 10, color: AppColors.gray2)),
            ],
          ),
          const SizedBox(width: 12),
          // Chat button
          Expanded(
            child: SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      contactName: shopName,
                      company: shopName,
                      conversationId: '',
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.dark, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Discuter maintenant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send inquiry button
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demande envoyée au fournisseur'), duration: Duration(seconds: 2)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  elevation: 0,
                ),
                child: const Text('Envoyer la demande', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mini chart painter for transaction trends
class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.4, size.height * 0.4),
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.35),
      Offset(size.width * 0.7, size.height * 0.15),
      Offset(size.width * 0.8, size.height * 0.25),
      Offset(size.width * 0.9, size.height * 0.1),
      Offset(size.width, size.height * 0.2),
    ];

    // Draw filled area
    final path = Path();
    path.moveTo(0, size.height);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
