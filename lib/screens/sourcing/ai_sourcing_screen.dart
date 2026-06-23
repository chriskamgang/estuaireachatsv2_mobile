import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../data/mock_data.dart';
import '../product/product_detail_screen.dart';

class AiSourcingScreen extends StatefulWidget {
  const AiSourcingScreen({super.key});

  @override
  State<AiSourcingScreen> createState() => _AiSourcingScreenState();
}

class _AiSourcingScreenState extends State<AiSourcingScreen>
    with SingleTickerProviderStateMixin {
  final _queryController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedCategory;
  bool _showFilters = false;

  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  List<_SourcingResult> _results = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _categories = [
    'Electronique',
    'Vetements',
    'Alimentation',
    'Beaute',
    'Maison',
    'Agriculture',
    'Industrie',
    'Automobile',
    'Sante',
    'Sport',
    'Jouets',
    'Bureau',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _quantityController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
      _results = [];
    });
    _pulseController.repeat(reverse: true);

    try {
      final body = <String, dynamic>{'query': query};
      if (_selectedCategory != null) body['category'] = _selectedCategory;
      if (_quantityController.text.isNotEmpty) {
        body['quantity'] = int.tryParse(_quantityController.text);
      }
      if (_budgetMinController.text.isNotEmpty) {
        body['budgetMin'] = double.tryParse(_budgetMinController.text);
      }
      if (_budgetMaxController.text.isNotEmpty) {
        body['budgetMax'] = double.tryParse(_budgetMaxController.text);
      }

      final res = await ApiService().post('/ai-sourcing/search', data: body);
      final data = res.data['data'] as List? ?? [];

      if (mounted) {
        setState(() {
          _results = data.map((p) {
            final images = p['images'] as List? ?? [];
            final mainImg = images.isNotEmpty
                ? images[0]['url'] as String
                : 'https://placehold.co/400x400/eee/999?text=No+Image';
            final shop = p['shop'] as Map<String, dynamic>?;
            final priceTiers = p['priceTiers'] as List? ?? [];

            double priceMin = (p['price'] as num?)?.toDouble() ?? 0;
            double priceMax = priceMin;
            if (priceTiers.length > 1) {
              priceMin =
                  (priceTiers.last['price'] as num?)?.toDouble() ?? priceMin;
              priceMax =
                  (priceTiers.first['price'] as num?)?.toDouble() ?? priceMax;
            }

            return _SourcingResult(
              product: MockProduct(
                id: p['id']?.toString() ?? '',
                name: p['name'] ?? '',
                image: mainImg,
                priceMin: priceMin,
                priceMax: priceMax,
                moq: (p['minOrderQty'] as num?)?.toInt() ?? 1,
                seller: shop?['name'] ?? '',
                origin: p['origin'] ?? 'CM',
                sellerYears:
                    (shop?['yearsActive'] as num?)?.toInt() ?? 1,
                verified: shop?['verified'] == true,
                sold: (p['totalSold'] as num?)?.toInt() ?? 0,
                rating: (p['rating'] as num?)?.toDouble() ?? 0,
                reviews: (p['totalReviews'] as num?)?.toInt() ?? 0,
                category: '',
              ),
              shopCity: shop?['city'] ?? '',
              shopCountry: shop?['country'] ?? 'CM',
              shopLogo: shop?['logo'] as String?,
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error =
              'Impossible de contacter le service de sourcing. Veuillez reessayer plus tard.';
        });
      }
    } finally {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text(
          'Agent de sourcing IA',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── Search input section ────────────────────────────────────

  Widget _buildSearchSection() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy_outlined,
                    size: 14, color: AppColors.blue),
                const SizedBox(width: 4),
                Text(
                  'Recherche assistee par IA',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Main query input
          TextField(
            controller: _queryController,
            maxLines: 2,
            minLines: 1,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _performSearch(),
            decoration: InputDecoration(
              hintText:
                  'Decrivez ce que vous recherchez...\nEx: Fournisseur de cacao en gros au Cameroun',
              hintMaxLines: 2,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.search, color: AppColors.gray3),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: _queryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _queryController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.gray6,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          // Filters toggle
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Row(
              children: [
                Icon(
                  _showFilters
                      ? Icons.tune_outlined
                      : Icons.tune_outlined,
                  size: 16,
                  color: AppColors.gray2,
                ),
                const SizedBox(width: 4),
                Text(
                  _showFilters ? 'Masquer les filtres' : 'Filtres avances',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray2,
                      fontWeight: FontWeight.w500),
                ),
                Icon(
                  _showFilters
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.gray3,
                ),
              ],
            ),
          ),

          // Optional filters
          if (_showFilters) ...[
            const SizedBox(height: 12),
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('Categorie (optionnel)',
                  style: TextStyle(fontSize: 13)),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.gray6,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 8),
            // Quantity
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Quantite souhaitee',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: AppColors.gray6,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            // Budget range
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _budgetMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Budget min (FCFA)',
                      hintStyle: const TextStyle(fontSize: 12),
                      filled: true,
                      fillColor: AppColors.gray6,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _budgetMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Budget max (FCFA)',
                      hintStyle: const TextStyle(fontSize: 12),
                      filled: true,
                      fillColor: AppColors.gray6,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _queryController.text.trim().isEmpty ? null : _performSearch,
              icon: const Icon(Icons.search, size: 18),
              label: const Text(
                'Rechercher',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.gray4,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (!_hasSearched) return _buildInitialState();
    if (_results.isEmpty) return _buildEmptyState();
    return _buildResultsList();
  }

  // ─── Initial state ──────────────────────────────────────────

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_outlined,
                  size: 48, color: AppColors.blue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Agent de sourcing intelligent',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              'Decrivez le produit ou le fournisseur que vous recherchez, et notre IA trouvera les meilleures correspondances pour vous.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.gray2, height: 1.5),
            ),
            const SizedBox(height: 24),
            // Suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Cacao en gros'),
                _buildSuggestionChip('Vetements enfants'),
                _buildSuggestionChip('Materiaux de construction'),
                _buildSuggestionChip('Telephones reconditiones'),
                _buildSuggestionChip('Huile de palme'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _queryController.text = text;
        setState(() {});
        _performSearch();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gray5),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.gray1),
        ),
      ),
    );
  }

  // ─── Loading state ──────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.smart_toy_outlined,
                    size: 40, color: AppColors.blue),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Notre agent IA analyse votre demande...',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              'Recherche des meilleurs fournisseurs et produits correspondants',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.gray3),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.gray5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error state ────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 36, color: AppColors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.gray1, height: 1.5),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: AppColors.orange),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray5.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 36, color: AppColors.gray3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun resultat trouve',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec des termes differents ou ajustez vos filtres pour de meilleurs resultats.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.gray2, height: 1.5),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildTipChip('Utilisez des termes plus generaux'),
                _buildTipChip('Verifiez l\'orthographe'),
                _buildTipChip('Reduisez le nombre de filtres'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gray6,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline, size: 12, color: AppColors.orange),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 11, color: AppColors.gray2)),
        ],
      ),
    );
  }

  // ─── Results list ───────────────────────────────────────────

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${_results.length} resultat${_results.length > 1 ? 's' : ''} trouve${_results.length > 1 ? 's' : ''}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray2),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildResultCard(_results[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(_SourcingResult result) {
    final product = result.product;
    final hasDiscount = product.priceMin < product.priceMax;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Image.network(
                product.image,
                width: 110,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 130,
                  color: AppColors.gray6,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.gray4, size: 32),
                ),
              ),
            ),
            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop info row
                    Row(
                      children: [
                        if (result.shopLogo != null)
                          CircleAvatar(
                            radius: 10,
                            backgroundImage:
                                NetworkImage(result.shopLogo!),
                            backgroundColor: AppColors.gray5,
                          )
                        else
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.blue.withOpacity(0.1),
                            child: Icon(Icons.storefront,
                                size: 10, color: AppColors.blue),
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.seller,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray1),
                          ),
                        ),
                        if (product.verified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    size: 10, color: AppColors.green),
                                const SizedBox(width: 2),
                                Text(
                                  'Verifie',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Product name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                          height: 1.3),
                    ),
                    const SizedBox(height: 6),

                    // Price range
                    Row(
                      children: [
                        Text(
                          hasDiscount
                              ? '${_formatPrice(product.priceMin)} - ${_formatPrice(product.priceMax)} FCFA'
                              : '${_formatPrice(product.priceMin)} FCFA',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // MOQ + Location
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 12, color: AppColors.gray3),
                        const SizedBox(width: 3),
                        Text(
                          'MOQ: ${product.moq}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.gray2),
                        ),
                        const SizedBox(width: 10),
                        if (result.shopCity.isNotEmpty ||
                            result.shopCountry.isNotEmpty) ...[
                          Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.gray3),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              [result.shopCity, result.shopCountry]
                                  .where((s) => s.isNotEmpty)
                                  .join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.gray2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}M';
    }
    final str = price.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

// ═══════════════════════════════════════════════════════════════
// Data model
// ═══════════════════════════════════════════════════════════════

class _SourcingResult {
  final MockProduct product;
  final String shopCity;
  final String shopCountry;
  final String? shopLogo;

  const _SourcingResult({
    required this.product,
    required this.shopCity,
    required this.shopCountry,
    this.shopLogo,
  });
}
