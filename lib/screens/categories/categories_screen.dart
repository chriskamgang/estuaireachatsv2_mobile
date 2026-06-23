import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import 'category_products_screen.dart';

// Mapping nom d'icone backend -> IconData Material
IconData _iconFromName(String name) {
  const map = <String, IconData>{
    'checkroom': Icons.checkroom,
    'smartphone': Icons.smartphone,
    'sports_soccer': Icons.sports_soccer,
    'face_retouching_natural': Icons.face_retouching_natural,
    'diamond': Icons.diamond,
    'home': Icons.home,
    'directions_run': Icons.directions_run,
    'hiking': Icons.hiking,
    'luggage': Icons.luggage,
    'inventory_2': Icons.inventory_2,
    'child_friendly': Icons.child_friendly,
    'cleaning_services': Icons.cleaning_services,
    'local_hospital': Icons.local_hospital,
    'card_giftcard': Icons.card_giftcard,
    'pets': Icons.pets,
    'menu_book': Icons.menu_book,
    'factory': Icons.factory,
    'storefront': Icons.storefront,
    'construction': Icons.construction,
    'domain': Icons.domain,
    'chair': Icons.chair,
    'lightbulb': Icons.lightbulb,
    'kitchen': Icons.kitchen,
    'build': Icons.build,
    'directions_car': Icons.directions_car,
    'hardware': Icons.hardware,
    'solar_power': Icons.solar_power,
    'electrical_services': Icons.electrical_services,
    'security': Icons.security,
    'forklift': Icons.forklift,
    'science': Icons.science,
    'settings': Icons.settings,
    'memory': Icons.memory,
    'local_shipping': Icons.local_shipping,
    'agriculture': Icons.agriculture,
    'category': Icons.category,
    'precision_manufacturing': Icons.precision_manufacturing,
    'handshake': Icons.handshake,
  };
  return map[name] ?? Icons.category;
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedIndex = 0;
  List<_Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await ApiService().get('/categories');
      final data = res.data['data'] as List? ?? [];

      final categories = data.map<_Category>((c) {
        final children = (c['children'] as List? ?? [])
            .map<_SubCategory>((s) => _SubCategory(
                  id: s['id'] ?? '',
                  name: s['name'] ?? '',
                  icon: s['icon'] ?? '',
                ))
            .toList();

        return _Category(
          id: c['id'] ?? '',
          name: c['name'] ?? '',
          icon: c['icon'] ?? '',
          children: children,
        );
      }).toList();

      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    if (_categories.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.category_outlined, size: 56, color: AppColors.gray4),
                const SizedBox(height: 12),
                const Text('Aucune catégorie', style: TextStyle(color: AppColors.gray2)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _loadCategories();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                  child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Catégories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
            ),
            Expanded(
              child: Row(
                children: [
                  // Left sidebar
                  SizedBox(
                    width: 100,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final isSelected = i == _selectedIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.white : AppColors.gray6,
                              border: Border(left: BorderSide(color: isSelected ? AppColors.orange : Colors.transparent, width: 3)),
                            ),
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                color: isSelected ? AppColors.dark : AppColors.gray2,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Right content
                  Expanded(
                    child: Container(
                      color: AppColors.white,
                      child: _CategoryContent(category: _categories[_selectedIndex]),
                    ),
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

class _Category {
  final String id;
  final String name;
  final String icon;
  final List<_SubCategory> children;

  const _Category({required this.id, required this.name, required this.icon, this.children = const []});
}

class _SubCategory {
  final String id;
  final String name;
  final String icon;

  const _SubCategory({required this.id, required this.name, this.icon = ''});
}

class _CategoryContent extends StatelessWidget {
  final _Category category;

  const _CategoryContent({required this.category});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Stock local', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.check_circle, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                const Text('Livraison rapide en 5 jours', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              Row(children: [
                Icon(Icons.check_circle, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                const Text('Pas de frais d\'importation', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // "Voir tous les produits" button
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryProductsScreen(
                categoryId: category.id,
                categoryName: category.name,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.grid_view, size: 18, color: AppColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Voir tous les produits ${category.name}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.orange),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.orange),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text('Sous-catégories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark)),
        const SizedBox(height: 12),

        // Sub-categories grid
        if (category.children.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: category.children.length,
            itemBuilder: (_, i) {
              final sub = category.children[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryProductsScreen(
                      categoryId: sub.id,
                      categoryName: sub.name,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.gray6,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(_iconFromName(sub.icon), color: AppColors.gray3, size: 28),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sub.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppColors.dark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(children: [
                const Icon(Icons.category, size: 48, color: AppColors.gray4),
                const SizedBox(height: 8),
                Text('Pas de sous-catégories', style: TextStyle(color: AppColors.gray3)),
              ]),
            ),
          ),
      ],
    );
  }
}
