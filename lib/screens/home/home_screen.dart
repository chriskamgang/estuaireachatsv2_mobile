import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/api_service.dart';
import '../../data/mock_data.dart';
import '../../providers/notification_provider.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';
import '../shop/shop_screen.dart';
import '../quote/quote_request_screen.dart';
import '../categories/categories_screen.dart';
import '../categories/category_products_screen.dart';
import '../../widgets/product_card.dart';

// ─── Helper: convertir un JSON produit API en MockProduct ──────
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Notification bell row
                  Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Consumer<NotificationProvider>(
                          builder: (context, notifProvider, _) {
                            return IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                );
                              },
                              icon: Badge(
                                isLabelVisible: notifProvider.unreadCount > 0,
                                label: Text(
                                  notifProvider.unreadCount > 9 ? '9+' : '${notifProvider.unreadCount}',
                                  style: const TextStyle(fontSize: 9),
                                ),
                                child: const Icon(Icons.notifications_outlined, size: 24, color: AppColors.dark),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Top tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.dark,
                    unselectedLabelColor: AppColors.gray3,
                    labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 14),
                    indicatorColor: AppColors.orange,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'AI Mode'),
                      Tab(text: 'Produits'),
                      Tab(text: 'Fabricants'),
                      Tab(text: 'Mondial'),
                    ],
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.gray6,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.orange, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(Icons.camera_alt_outlined, color: AppColors.gray3, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Rechercher des produits...', style: TextStyle(color: AppColors.gray3, fontSize: 14)),
                            ),
                            Icon(Icons.mic_none, color: AppColors.gray3, size: 20),
                            const SizedBox(width: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(18)),
                              child: const Icon(Icons.search, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _AIModeTab(),
              _ProductsTab(),
              _FabricantsTab(),
              _MondialTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<MockProduct> _featuredProducts = [];
  List<MockProduct> _gridProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService().get('/products/featured'),
        ApiService().get('/products', params: {'perPage': 20, 'sort': 'newest'}),
      ]);

      final featuredData = results[0].data['data'] as List? ?? [];
      final gridData = results[1].data['data'] as List? ?? [];

      if (mounted) {
        setState(() {
          _featuredProducts = featuredData.take(4).map((p) => _productFromApi(p as Map<String, dynamic>)).toList();
          _gridProducts = gridData.map((p) => _productFromApi(p as Map<String, dynamic>)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _featuredProducts = [];
          _gridProducts = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 3 shortcuts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _ShortcutButton(icon: Icons.explore, label: 'Explorer par\ncatégories', color: AppColors.orange, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
              }),
              const SizedBox(width: 8),
              _ShortcutButton(icon: Icons.request_quote, label: 'Demander\nun devis', color: AppColors.red, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteRequestScreen()));
              }),
              const SizedBox(width: 8),
              _ShortcutButton(icon: Icons.emoji_events, label: 'Top du\nclassement', color: AppColors.orange, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryProductsScreen(
                  categoryId: '',
                  categoryName: 'Top du classement',
                )));
              }),
            ],
          ),
        ),
        // Promo banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, size: 16, color: AppColors.orange),
                        const SizedBox(width: 4),
                        const Text('Livraison GRATUITE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    Text('sur votre premiere commande', style: TextStyle(fontSize: 10, color: AppColors.gray3)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.gray5),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield, size: 16, color: AppColors.orange),
                        const SizedBox(width: 4),
                        const Expanded(child: Text('Protection de rembours...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    Text('pendant 60 jours maximum', style: TextStyle(fontSize: 10, color: AppColors.gray3)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // History section
        if (_featuredProducts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = _featuredProducts[i];
                  return Container(
                    width: 85,
                    decoration: BoxDecoration(
                      color: AppColors.gray6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(p.image, width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppColors.gray5)),
                        ),
                        const SizedBox(height: 4),
                        Text(formatPrice(p.priceMin), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.orange), maxLines: 1),
                        if (i == 0) Text('Historique', style: TextStyle(fontSize: 8, color: AppColors.gray3)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Filter tabs
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _FilterChip(label: 'Tous', selected: true),
              _FilterChip(label: 'Meilleures offres', selected: false),
              _FilterChip(label: 'Personnalisation rapide', selected: false),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Products grid
        if (_gridProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('Aucun produit disponible', style: TextStyle(color: AppColors.gray3, fontSize: 13))),
          )
        else
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
              itemCount: _gridProducts.length,
              itemBuilder: (_, i) => ProductCard(product: _gridProducts[i]),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AIModeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [Icon(Icons.auto_awesome, size: 14, color: AppColors.orange), SizedBox(width: 4), Text('600', style: TextStyle(fontSize: 12)), SizedBox(width: 4), Text('Gratuit', style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w700))]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFFEECEC), borderRadius: BorderRadius.circular(8)),
          child: const Text('Essayez maintenant — 100 crédits gratuits par jour !', style: TextStyle(color: AppColors.orange, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 24),
        const Text('Sourcing intelligent avec le ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
        const Text('Mode IA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.orange)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text('Nouveau', style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700)), SizedBox(width: 8), Expanded(child: Text('Des idees a la production', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)))]),
                SizedBox(height: 4),
                Text('Concevez votre prochain succes avec le Mode IA', style: TextStyle(fontSize: 12, color: AppColors.gray2)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(16)),
                child: const Text('Tester', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...[
          'Votre meilleur fournisseur est ici',
          'Voir les tendances de votre marche',
        ].map((t) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [const Icon(Icons.auto_awesome, size: 16, color: AppColors.orange), const SizedBox(width: 10), Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))), const Icon(Icons.chevron_right, color: AppColors.gray3)]),
        )),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Recherche de fabricants vérifiés', 'Concevoir avec l\'IA', 'Recherche de produit', 'Analyser les best-sellers', 'Évaluer le potentiel du marché'].map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(20)),
            child: Text(t, style: const TextStyle(fontSize: 13, color: AppColors.gray1)),
          )).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Decrivez vos besoins...',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.camera_alt_outlined, color: AppColors.gray3),
                  const Spacer(),
                  Icon(Icons.mic, color: AppColors.gray3),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FabricantsTab extends StatefulWidget {
  @override
  State<_FabricantsTab> createState() => _FabricantsTabState();
}

class _FabricantsTabState extends State<_FabricantsTab> {
  List<MockProduct> _featuredProducts = [];
  List<Map<String, dynamic>> _shops = [];
  Map<String, List<MockProduct>> _shopProducts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService().get('/products/featured'),
        ApiService().get('/shops', params: {'perPage': 5}),
      ]);

      final featuredData = results[0].data['data'] as List? ?? [];
      final shopsData = results[1].data['data'] as List? ?? [];

      final featured = featuredData.map((p) => _productFromApi(p as Map<String, dynamic>)).toList();
      final shops = shopsData.map((s) => s as Map<String, dynamic>).toList();

      // Charger les produits de chaque shop en parallele
      final shopProductFutures = shops.map((s) =>
        ApiService().get('/products', params: {'shopId': s['id']?.toString(), 'perPage': 3}),
      ).toList();

      final shopProductResults = await Future.wait(shopProductFutures);
      final shopProdsMap = <String, List<MockProduct>>{};
      for (var i = 0; i < shops.length; i++) {
        final shopId = shops[i]['id']?.toString() ?? '';
        final prodData = shopProductResults[i].data['data'] as List? ?? [];
        shopProdsMap[shopId] = prodData.map((p) => _productFromApi(p as Map<String, dynamic>)).toList();
      }

      if (mounted) {
        setState(() {
          _featuredProducts = featured;
          _shops = shops;
          _shopProducts = shopProdsMap;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _featuredProducts = [];
          _shops = [];
          _shopProducts = {};
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Sub-categories scroll
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Tous', 'Pieces & Accessoires', 'Machines pour le Bati...', 'Electronique'].map((t) {
                final isFirst = t == 'Tous';
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isFirst ? AppColors.dark : AppColors.gray6,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(t, style: TextStyle(fontSize: 12, color: isFirst ? Colors.white : AppColors.gray1, fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal)),
                );
              }).toList(),
            ),
          ),
        ),

        // 3 shortcuts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _ShortcutButton(icon: Icons.explore, label: 'Explorer par\ncatégories', color: AppColors.primary, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
              }),
              const SizedBox(width: 8),
              _ShortcutButton(icon: Icons.request_quote, label: 'Demander\nun devis', color: AppColors.primary, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteRequestScreen()));
              }),
              const SizedBox(width: 8),
              _ShortcutButton(icon: Icons.verified, label: 'Fournisseur\nprofessionne...', color: AppColors.secondary, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Correspondances d'usine
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Expanded(child: Text('Correspondances d\'usine pour les vues récentes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            const Icon(Icons.arrow_forward, size: 18),
          ]),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 165,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _featuredProducts.length.clamp(0, 4),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = _featuredProducts[i];
              return SizedBox(
                width: 130,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.image, width: 130, height: 100, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 130, height: 100, color: AppColors.gray5)),
                  ),
                  const SizedBox(height: 6),
                  Text('${i + 2} usines', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text('À partir de ${formatPrice(p.priceMin)}', style: TextStyle(fontSize: 11, color: AppColors.gray3)),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Testez nos echantillons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Expanded(child: Text('Testez nos échantillons', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            const Icon(Icons.arrow_forward, size: 18),
          ]),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _featuredProducts.length.clamp(0, 4),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final idx = (_featuredProducts.length > 4) ? i + 4 : i;
              final p = _featuredProducts[idx.clamp(0, _featuredProducts.length - 1)];
              return SizedBox(
                width: 140,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.image, width: 140, height: 110, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 140, height: 110, color: AppColors.gray5)),
                  ),
                  const SizedBox(height: 6),
                  Text('Prix de l\'échantillon :', style: TextStyle(fontSize: 11, color: AppColors.gray3)),
                  Text(formatPrice(p.priceMin), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Personnalisation rapide
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_fix_high, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              const Expanded(child: Text('Personnalisation rapide', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              const Icon(Icons.arrow_forward, size: 18),
            ]),
            const SizedBox(height: 2),
            Text('Faible MOQ \u2022 Expédition sous 14 jours \u2022 Conforme au design', style: TextStyle(fontSize: 11, color: AppColors.gray3)),
          ]),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _featuredProducts.length.clamp(0, 4),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final idx = (_featuredProducts.length > 8) ? i + 8 : i;
              final p = _featuredProducts[idx.clamp(0, _featuredProducts.length - 1)];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(p.image, width: 130, height: 120, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 130, height: 120, color: AppColors.gray5)),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Fabricants au top du classement
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Fabricants au top du classement', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _featuredProducts.length.clamp(0, 3),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = _featuredProducts[i];
              final labels = ['Les plus populaires', 'Meilleures ventes', 'Classement'];
              final cats = ['Batteries automobiles', 'Démarreurs automobi...', 'Pare-soleil, déflecteur...'];
              return SizedBox(
                width: 140,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(p.image, width: 140, height: 100, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 140, height: 100, color: AppColors.gray5)),
                    ),
                    Positioned(
                      bottom: 4, left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: i < 2 ? AppColors.primary : AppColors.secondary, borderRadius: BorderRadius.circular(4)),
                        child: Text(i < 2 ? 'TOP' : 'Classement', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(labels[i], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  Text(cats[i], style: TextStyle(fontSize: 11, color: AppColors.gray3), overflow: TextOverflow.ellipsis),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Personnalisation à partir d\'échantillons', 'Gestion de la qualité certifiée'].map((t) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: AppColors.gray5), borderRadius: BorderRadius.circular(20)),
                child: Text(t, style: const TextStyle(fontSize: 12, color: AppColors.gray1)),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Manufacturer cards
        ..._buildManufacturerCards(context),

        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildManufacturerCards(BuildContext context) {
    if (_shops.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('Aucun fabricant disponible', style: TextStyle(color: AppColors.gray3, fontSize: 13))),
        ),
      ];
    }

    return _shops.map((shop) {
      final shopId = shop['id']?.toString() ?? '';
      final shopName = shop['name'] ?? '';
      final shopLogo = shop['logo'] ?? 'https://placehold.co/40x40/eee/999?text=S';
      final yearsActive = shop['yearsActive'] ?? 1;
      final verified = shop['verified'] == true;
      final rating = shop['rating'] ?? 0;
      final description = shop['description'] ?? '';
      final prods = _shopProducts[shopId] ?? [];

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(shopName: shopName))),
          child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: logo + name + info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(shopLogo, width: 40, height: 40, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: AppColors.gray5)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shopName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Row(children: [
                            if (verified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFE82328)]),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text('Vérifié', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                            if (verified) const SizedBox(width: 6),
                            Expanded(
                              child: Text('$yearsActive ans',
                                style: TextStyle(fontSize: 11, color: AppColors.gray3), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Capabilities / description
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Text(description.isNotEmpty ? description : 'Fabricant professionnel', style: TextStyle(fontSize: 11, color: AppColors.gray2), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              // 3 products
              if (prods.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: List.generate(prods.length.clamp(0, 3), (pi) {
                      final p = prods[pi];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: pi < 2 ? 8 : 0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Stack(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(p.image, height: 90, width: double.infinity, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(height: 90, color: AppColors.gray5)),
                              ),
                              Positioned(
                                bottom: 4, left: 4,
                                child: Container(
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                                  child: const Icon(Icons.search, size: 14, color: AppColors.gray2),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Text(formatPrice(p.priceMin), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            Text('${p.moq} pièces (qté min.)', style: TextStyle(fontSize: 10, color: AppColors.gray3)),
                          ]),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        ),
      );
    }).toList();
  }
}

class _MondialTab extends StatefulWidget {
  @override
  State<_MondialTab> createState() => _MondialTabState();
}

class _MondialTabState extends State<_MondialTab> {
  List<MockProduct> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiService().get('/products', params: {'perPage': 20});
      final data = res.data['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _products = data.map((p) => _productFromApi(p as Map<String, dynamic>)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _products = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Country filters
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _CountryChip(label: 'Monde', countryCode: '', selected: true),
              _CountryChip(label: 'Chine', countryCode: 'cn', selected: false),
              _CountryChip(label: 'Pakistan', countryCode: 'pk', selected: false),
              _CountryChip(label: 'Inde', countryCode: 'in', selected: false),
              _CountryChip(label: 'Vietnam', countryCode: 'vn', selected: false),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_products.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('Aucun produit disponible', style: TextStyle(color: AppColors.gray3, fontSize: 13))),
          )
        else
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
              itemCount: _products.length,
              itemBuilder: (_, i) => ProductCard(product: _products[i]),
            ),
          ),
      ],
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ShortcutButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), maxLines: 2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.dark : AppColors.gray6,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          if (selected) ...[const Icon(Icons.favorite, size: 12, color: AppColors.red), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.gray1, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  final String label;
  final String countryCode;
  final bool selected;

  const _CountryChip({required this.label, required this.countryCode, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.dark : AppColors.gray6,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          if (countryCode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Image.network(
                'https://flagcdn.com/w20/$countryCode.png',
                width: 18,
                height: 13,
                errorBuilder: (_, __, ___) => const Icon(Icons.public, size: 14),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.public, size: 16, color: Colors.white),
            ),
          Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.gray1)),
        ],
      ),
    );
  }
}
