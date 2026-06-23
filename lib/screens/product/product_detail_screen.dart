import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/mock_data.dart';
import '../../providers/cart_provider.dart';
import '../search/search_screen.dart';
import '../cart/cart_screen.dart';
import '../checkout/checkout_screen.dart';
import '../messaging/chat_screen.dart';
import '../shop/shop_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final MockProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentImage = 0;

  bool _isLoading = true;
  String? _error;

  List<String> _images = [];
  Map<String, dynamic>? _productData;
  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> _colors = [];
  List<MockProduct> _otherProducts = [];
  Map<String, dynamic>? _shopData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ApiService().get('/products/${widget.product.id}');
      final data = res.data as Map<String, dynamic>;
      final images = data['images'] as List? ?? [];
      _images = images.map<String>((img) => img['url'] as String).toList();
      if (_images.isEmpty) {
        _images = ['https://placehold.co/600x600/eee/999?text=No+Image'];
      }
      _productData = data;
      _variants = (data['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _colors = (data['colors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _shopData = data['shop'] as Map<String, dynamic>?;

      // Load other products from same shop
      if (_shopData != null && _shopData!['id'] != null) {
        try {
          final shopRes = await ApiService().get('/products', params: {
            'shopId': _shopData!['id'],
            'perPage': 4,
          });
          final shopData = shopRes.data;
          final List productsList = shopData is Map ? (shopData['data'] as List? ?? []) : (shopData as List? ?? []);
          _otherProducts = productsList
              .where((p) => p['id'] != data['id'])
              .take(4)
              .map<MockProduct>((p) => _productFromApi(p))
              .toList();
        } catch (_) {}
      }

      setState(() { _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Erreur de chargement'; });
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

  // Helpers to read from API data with fallback to widget.product
  double get _price => (_productData?['price'] as num?)?.toDouble() ?? widget.product.priceMin;
  int get _moq => (_productData?['minOrderQty'] as num?)?.toInt() ?? widget.product.moq;
  String get _name => _productData?['name'] ?? widget.product.name;
  double get _rating => (_productData?['rating'] as num?)?.toDouble() ?? widget.product.rating;
  int get _reviews => (_productData?['totalReviews'] as num?)?.toInt() ?? widget.product.reviews;
  String get _origin => _productData?['origin'] ?? widget.product.origin;
  String get _seller => _shopData?['name'] ?? widget.product.seller;
  bool get _verified => _shopData?['verified'] == true || widget.product.verified;
  int get _sellerYears => (_shopData?['yearsActive'] as num?)?.toInt() ?? widget.product.sellerYears;
  String get _shopSlug => _shopData?['slug'] ?? '';
  String get _categoryName => (_productData?['category'] as Map?)?['name'] ?? widget.product.category;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: AppColors.gray2, fontSize: 15)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadProductDetails,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _buildContent(p),
          ),
          // Bottom bar
          Container(
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                // Magasin
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ShopScreen(shopName: _seller, shopSlug: _shopSlug)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.store_outlined, size: 22, color: AppColors.gray2),
                      const Text('Magasin', style: TextStyle(fontSize: 10, color: AppColors.gray2)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Chat
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        contactName: _seller,
                        company: _seller,
                        conversationId: '',
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_outlined, size: 22, color: AppColors.gray2),
                      const Text('Discuter', style: TextStyle(fontSize: 10, color: AppColors.gray2)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Ajouter au panier
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<CartProvider>().addItem(CartItem(
                        id: p.id,
                        name: _name,
                        image: _images.isNotEmpty ? _images[0] : p.image,
                        price: _price,
                        seller: _seller,
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ajouté au panier'), backgroundColor: AppColors.green, duration: Duration(seconds: 1)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.orange),
                      foregroundColor: AppColors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Ajouter au panier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                // Acheter maintenant
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<CartProvider>().addItem(CartItem(
                        id: p.id,
                        name: _name,
                        image: _images.isNotEmpty ? _images[0] : p.image,
                        price: _price,
                        seller: _seller,
                      ));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Acheter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MockProduct p) {
    return CustomScrollView(
      slivers: [
        // App bar with image gallery
        SliverAppBar(
          expandedHeight: 360,
          pinned: true,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          actions: [
            _CircleButton(
              icon: Icons.search,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
            _CircleButton(
              icon: Icons.shopping_cart_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
            _CircleButton(
              icon: Icons.more_horiz,
              onTap: () => showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(color: AppColors.gray4, borderRadius: BorderRadius.circular(2)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.share_outlined),
                        title: const Text('Partager'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lien copié dans le presse-papiers'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag_outlined, color: AppColors.primary),
                        title: const Text('Signaler'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signalement envoyé'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.store_outlined),
                        title: const Text('Voir la boutique'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(shopName: _seller, shopSlug: _shopSlug)));
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
                PageView.builder(
                  itemCount: _images.length,
                  onPageChanged: (i) => setState(() => _currentImage = i),
                  itemBuilder: (_, i) => Image.network(
                    _images[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.gray5),
                  ),
                ),
                // Favorite + visual search
                Positioned(
                  right: 12,
                  top: MediaQuery.of(context).padding.top + 56,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                        child: const Icon(Icons.favorite_border, size: 20, color: AppColors.dark),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                        child: const Icon(Icons.image_search, size: 20, color: AppColors.dark),
                      ),
                    ],
                  ),
                ),
                // Image tabs
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ImageTab(label: 'Photos ${_currentImage + 1}/${_images.length}', selected: true),
                      _ImageTab(label: 'Vehicule', selected: false),
                      _ImageTab(label: 'Points forts', selected: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Promo banner
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, size: 16, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Expanded(child: RichText(text: TextSpan(style: const TextStyle(fontSize: 12, color: AppColors.dark), children: [
                      TextSpan(text: 'Economisez 10 000 FCFA ', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.orange)),
                      const TextSpan(text: 'sur les commandes de plus de 100 000 FCFA'),
                    ]))),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.gray3),
                  ],
                ),
              ),
              // Price tiers
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _PriceTier(price: formatPrice(_price), label: 'Commande minimale : $_moq pièces', highlighted: true),
                    _PriceTier(price: formatPrice(_price * 0.9), label: '${_moq * 5}-${_moq * 10} pièces', highlighted: false),
                    _PriceTier(price: formatPrice(_price * 0.8), label: '>=  ${_moq * 10} pièces', highlighted: false),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(_name, style: const TextStyle(fontSize: 14, color: AppColors.dark, height: 1.4))),
                    const SizedBox(width: 8),
                    const Icon(Icons.share, size: 18, color: AppColors.gray3),
                  ],
                ),
              ),
              // Shop rating
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text('Note de la boutique: ', style: TextStyle(fontSize: 12, color: AppColors.gray2)),
                    Text('$_rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    Text(' ($_reviews)', style: TextStyle(fontSize: 12, color: AppColors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Verified supplier
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: AppColors.gray5), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.gray5, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            if (_verified) Text('Vérifié ', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 12)),
                            Text('Fournisseur : ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            Expanded(child: Text(_seller, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ]),
                        ])),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.gray3),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _SupplierBadge('Personnalisation simple'),
                        _SupplierBadge('Fournisseur polyvalent'),
                        _SupplierBadge('Taux de rachat : 23%'),
                        _SupplierBadge('$_sellerYears ans sur EA'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Variants / Colors from API
              if (_colors.isNotEmpty) ...[
                _SectionTitle('Couleur (${_colors.length})'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    children: _colors.map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.gray4), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c['code'] != null) ...[
                            Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                color: _parseColor(c['code']),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.gray4, width: 0.5),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(c['name'] ?? '', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ] else if (_variants.isNotEmpty) ...[
                _SectionTitle('Variantes (${_variants.length})'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _variants.map((v) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.gray4), borderRadius: BorderRadius.circular(6)),
                      child: Text(v['name'] ?? '', style: const TextStyle(fontSize: 13)),
                    )).toList(),
                  ),
                ),
              ] else ...[
                _SectionTitle('Couleur (3)'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    children: ['Naturel Blanc', 'Noir', 'Rouge'].map((v) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.gray4), borderRadius: BorderRadius.circular(6)),
                      child: Text(v, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Protection
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Protection des commandes EstuaireAchats', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.gray3),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.verified_user, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      const Text('Paiements sécurisés ', style: TextStyle(fontSize: 11)),
                      ...['VISA', 'MC', 'PayPal'].map((c) => Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.gray5, borderRadius: BorderRadius.circular(2)),
                        child: Text(c, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                      )),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.shield, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      const Text('Protection de remboursement', style: TextStyle(fontSize: 11)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Characteristics from API
              _SectionTitle('Caractéristiques'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _CharRow('Origine', _origin == 'CN' ? 'Chine' : (_origin == 'CM' ? 'Cameroun' : _origin)),
                    _CharRow('Qté min.', '$_moq pièces'),
                    _CharRow('Categorie', _categoryName),
                    if (_productData?['brand'] != null)
                      _CharRow('Marque', (_productData!['brand'] as Map?)?['name'] ?? ''),
                    if (_productData?['weight'] != null)
                      _CharRow('Poids', '${_productData!['weight']} kg'),
                    if (_productData?['dimensions'] != null)
                      _CharRow('Dimensions', '${_productData!['dimensions']}'),
                    _CharRow('Garantie', _productData?['warranty'] ?? '1 an'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Shipping timeline
              _ShippingTimeline(origin: _origin),
              const SizedBox(height: 12),
              // Tabs: Apercu / Details / Autres produits
              TabBar(
                controller: _tabController,
                labelColor: AppColors.dark,
                unselectedLabelColor: AppColors.gray3,
                indicatorColor: AppColors.dark,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Aperçu'),
                  Tab(text: 'Détails'),
                  Tab(text: 'Autres produits'),
                ],
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Apercu - more product info
                    Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description, size: 48, color: AppColors.gray4),
                          const SizedBox(height: 8),
                          Text(_productData?['description'] ?? 'Informations détaillées du produit', style: TextStyle(color: AppColors.gray3)),
                        ],
                      ),
                    )),
                    // Details - supplier images
                    Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 48, color: AppColors.gray4),
                          const SizedBox(height: 8),
                          Text('Images descriptives du fournisseur', style: TextStyle(color: AppColors.gray3)),
                        ],
                      ),
                    )),
                    // Other products from same shop
                    _otherProducts.isEmpty
                        ? Center(child: Text('Aucun autre produit', style: TextStyle(color: AppColors.gray3)))
                        : GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _otherProducts.length,
                            itemBuilder: (_, i) {
                              final op = _otherProducts[i];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: op)),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        child: Image.network(
                                          op.image,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (_, __, ___) => Container(
                                            decoration: BoxDecoration(color: AppColors.gray5, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                                          ),
                                        ),
                                      )),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(op.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                                          const SizedBox(height: 4),
                                          Text(formatPriceRange(op.priceMin, op.priceMax), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                          Text('Quantité min. : ${op.moq} pièces', style: TextStyle(fontSize: 9, color: AppColors.gray3)),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
              // Similar products
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.image_search, size: 16, color: AppColors.gray3),
                  const SizedBox(width: 6),
                  const Text('Produits similaires', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Color _parseColor(String code) {
    try {
      final hex = code.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.gray4;
    }
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ImageTab extends StatelessWidget {
  final String label;
  final bool selected;

  const _ImageTab({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.black54 : Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
    );
  }
}

class _PriceTier extends StatelessWidget {
  final String price;
  final String label;
  final bool highlighted;

  const _PriceTier({required this.price, required this.label, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFF9F9F9) : AppColors.white,
          border: Border(bottom: BorderSide(color: highlighted ? AppColors.dark : AppColors.gray5, width: highlighted ? 2 : 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: highlighted ? AppColors.dark : AppColors.gray1)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.gray3), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.gray3),
        ],
      ),
    );
  }
}

class _SupplierBadge extends StatelessWidget {
  final String label;
  const _SupplierBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, color: AppColors.blue)),
    );
  }
}

class _CharRow extends StatelessWidget {
  final String label;
  final String value;
  const _CharRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.gray2))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.dark))),
        ],
      ),
    );
  }
}

class _ShippingTimeline extends StatelessWidget {
  final String origin;
  const _ShippingTimeline({required this.origin});

  static const _countryNames = {
    'CN': 'Chine', 'FR': 'France', 'US': 'USA', 'DE': 'Allemagne',
    'JP': 'Japon', 'TR': 'Turquie', 'IN': 'Inde', 'KR': 'Coree',
    'VN': 'Vietnam', 'TH': 'Thailande', 'MY': 'Malaisie', 'BR': 'Bresil',
  };

  @override
  Widget build(BuildContext context) {
    final isInternational = origin.toUpperCase() != 'CM';
    final originLabel = _countryNames[origin.toUpperCase()] ?? origin;
    final intlDays = origin.toUpperCase() == 'CN' ? 25 : 20;
    const localDays = 3;

    if (isInternational) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, size: 14, color: AppColors.orange),
                const SizedBox(width: 6),
                const Text('Estimation livraison', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Origin
                _TimelineNode(
                  icon: Icons.flight_takeoff,
                  color: AppColors.orange,
                  label: originLabel,
                  sublabel: null,
                ),
                // Line 1
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(height: 2, color: AppColors.orange.withValues(alpha: 0.2)),
                          FractionallySizedBox(
                            widthFactor: 0.6,
                            child: Container(height: 2, color: AppColors.orange.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('$intlDays-${intlDays + 10}j', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.orange)),
                    ],
                  ),
                ),
                // Warehouse
                _TimelineNode(
                  icon: Icons.warehouse,
                  color: AppColors.orange,
                  label: 'Entrepot',
                  sublabel: 'Douala',
                ),
                // Line 2 with Merci E
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(height: 2, color: const Color(0xFF00A06A).withValues(alpha: 0.2)),
                          FractionallySizedBox(
                            widthFactor: 0.8,
                            child: Container(height: 2, color: const Color(0xFF00A06A).withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Merci E', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF00A06A))),
                      Text('$localDays-${localDays + 2}j', style: TextStyle(fontSize: 8, color: const Color(0xFF00A06A).withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                // Client
                const _TimelineNode(
                  icon: Icons.local_shipping,
                  color: Color(0xFF00A06A),
                  label: 'Client',
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Local (Cameroon)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF5),
        border: Border.all(color: const Color(0xFF00A06A).withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, size: 14, color: Color(0xFF00A06A)),
              const SizedBox(width: 6),
              const Text('Estimation livraison', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const _TimelineNode(
                icon: Icons.warehouse,
                color: Color(0xFF00A06A),
                label: 'Vendeur',
                sublabel: 'Cameroun',
              ),
              Expanded(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(height: 2, color: const Color(0xFF00A06A).withValues(alpha: 0.2)),
                        FractionallySizedBox(
                          widthFactor: 0.8,
                          child: Container(height: 2, color: const Color(0xFF00A06A).withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Merci E', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF00A06A))),
                    Text('$localDays-${localDays + 2}j', style: TextStyle(fontSize: 8, color: const Color(0xFF00A06A).withValues(alpha: 0.7))),
                  ],
                ),
              ),
              const _TimelineNode(
                icon: Icons.local_shipping,
                color: Color(0xFF00A06A),
                label: 'Client',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? sublabel;

  const _TimelineNode({
    required this.icon,
    required this.color,
    required this.label,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.dark)),
        if (sublabel != null)
          Text(sublabel!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}
