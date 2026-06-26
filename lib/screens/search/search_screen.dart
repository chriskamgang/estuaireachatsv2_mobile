import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../data/mock_data.dart';
import '../../widgets/product_card.dart';
import 'filters_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<MockProduct> _results = [];
  bool _hasSearched = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
  }

  /// Enregistre la recherche en arriere-plan (fire and forget)
  void _saveSearchHistory(String query) {
    if (query.trim().isEmpty) return;
    // Verifier si l'utilisateur est connecte avant d'envoyer
    ApiService().getToken().then((token) {
      if (token != null) {
        ApiService()
            .post('/search-history', data: {'query': query.trim()})
            .catchError((_) => null);
      }
    });
  }

  Future<void> _search(String query) async {
    // Sauvegarder la recherche en arriere-plan
    _saveSearchHistory(query);

    setState(() {
      _hasSearched = true;
      _loading = true;
    });

    try {
      final params = <String, dynamic>{
        'perPage': 40,
        'page': 1,
      };
      if (query.isNotEmpty) {
        params['search'] = query;
      }

      final res = await ApiService().get('/products', params: params);
      final data = res.data['data'] as List? ?? [];

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
          category: '',
        );
      }).toList();

      setState(() {
        _results = products;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.gray4, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Recherche par image', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.orange),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSearch(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.orange),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSearch(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSearch(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      setState(() {
        _hasSearched = true;
        _loading = true;
      });

      _controller.text = 'Recherche par image...';

      // Envoyer l'image au backend pour recherche visuelle CLIP
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        ),
      });

      final res = await ApiService().post(
        '/ai-sourcing/image-search',
        data: formData,
      );

      final data = res.data['data'] as List? ?? [];

      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun produit similaire trouve')),
          );
          setState(() {
            _results = [];
            _loading = false;
          });
        }
        return;
      }

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
          category: '',
        );
      }).toList();

      setState(() {
        _results = products;
        _loading = false;
        _controller.text = 'Resultats par image';
      });
    } catch (e) {
      if (mounted) {
        final message = e is DioException && e.response?.statusCode == 503
            ? 'Le service de recherche visuelle est indisponible'
            : 'Erreur : ${e.toString().replaceAll('Exception: ', '')}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        setState(() {
          _loading = false;
          _controller.text = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(20)),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'Rechercher des produits...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                onPressed: _showImageSourcePicker,
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.search, color: Colors.white, size: 18),
            ),
            onPressed: () => _search(_controller.text),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: !_hasSearched
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Recherches populaires', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Smartphone Samsung', 'Ecouteurs Bluetooth', 'Chaussures sport', 'Alarme voiture', 'Panneau solaire', 'Robe africaine'].map((t) => GestureDetector(
                    onTap: () {
                      _controller.text = t;
                      _search(t);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(20)),
                      child: Text(t, style: const TextStyle(fontSize: 13)),
                    ),
                  )).toList(),
                ),
              ],
            )
          : Column(
              children: [
                // Filter bar
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FiltersScreen())),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.gray4), borderRadius: BorderRadius.circular(16)),
                          child: const Row(children: [Icon(Icons.tune, size: 14), SizedBox(width: 4), Text('Filtres', style: TextStyle(fontSize: 12))]),
                        ),
                      ),
                      ...['Fournisseur vérifié', 'Livraison sous 20 jours'].map((t) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.gray4), borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.center,
                        child: Text(t, style: const TextStyle(fontSize: 12)),
                      )),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                      : _results.isEmpty
                      ? const Center(child: Text('Aucun resultat', style: TextStyle(color: AppColors.gray3)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (_, i) => ProductCard(product: _results[i]),
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
