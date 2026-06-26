import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/mock_data.dart';
import '../../widgets/product_card.dart';
import '../auth/login_screen.dart';
import '../orders/orders_screen.dart';
import '../favorites/favorites_screen.dart';
import '../settings/settings_screen.dart';
import '../addresses/addresses_screen.dart';
import '../quote/quote_request_screen.dart';
import '../quote/my_quotes_screen.dart';
import '../notifications/notifications_screen.dart';
import '../wallet/wallet_screen.dart';
import '../history/browsing_history_screen.dart';
import '../coupons/coupons_screen.dart';
import '../referral/referral_screen.dart';
import '../flash_deals/flash_deals_screen.dart';
import '../invoices/invoices_screen.dart';
import '../support/support_screen.dart';
import '../search/search_screen.dart';
import '../sourcing/ai_sourcing_screen.dart';
import '../subscription/subscription_screen.dart';
import '../qrcode/qr_screen.dart';
import '../settings/tax_info_screen.dart';
import '../certificates/certificates_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _inspirationTab = 0;
  List<MockProduct> _inspirationProducts = [];
  bool _inspirationLoading = true;
  int _favoritesCount = 0;
  int _couponsCount = 0;

  @override
  void initState() {
    super.initState();
    // Charge le nombre de notifs non lues au demarrage du profil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchUnreadCount();
      _loadCounts();
    });
    _loadInspirationProducts();
  }

  Future<void> _loadInspirationProducts() async {
    try {
      final res = await ApiService().get('/products/featured');
      final data = res.data['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _inspirationProducts = data.map((p) {
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
          _inspirationLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _inspirationProducts = [];
          _inspirationLoading = false;
        });
      }
    }
  }

  Future<void> _loadCounts() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      final results = await Future.wait([
        ApiService().get('/wishlists'),
        ApiService().get('/coupons/me'),
      ]);
      if (!mounted) return;
      final favData = results[0].data['data'] as List? ?? [];
      final couponData = results[1].data['data'] as List? ?? [];
      setState(() {
        _favoritesCount = favData.length;
        _couponsCount = couponData.length;
      });
    } catch (_) {}
  }

  // ─── Helper: dialog "bientot disponible" ───────────────────
  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(feature, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Cette fonctionnalité sera bientôt disponible.',
          style: TextStyle(color: AppColors.gray2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ─── Helper: dialog "Commencez a vendre" ────────────────────
  void _showSellDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Commencez à vendre',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.storefront_outlined, color: AppColors.green, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pour devenir vendeur, téléchargez l\'application EstuaireAchats Vendeur disponible sur le Play Store et l\'App Store.',
              style: TextStyle(color: AppColors.gray1, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: AppColors.gray2)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Helper: require auth or redirect to login ──────────
  void _requireAuth(VoidCallback action) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray6,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context, auth),
            const SizedBox(height: 10),
            _buildShortcutTiles(),
            if (auth.isAuthenticated) ...[
              const SizedBox(height: 10),
              _buildPaymentBanner(),
              const SizedBox(height: 10),
              _buildOrdersSection(),
              const SizedBox(height: 10),
              _buildPaymentFinancing(),
            ],
            const SizedBox(height: 10),
            _buildMoreFeatures(),
            const SizedBox(height: 10),
            _buildReferralBanner(),
            const SizedBox(height: 10),
            _buildPromoBanner(),
            const SizedBox(height: 10),
            _buildAiSourcingLink(),
            _buildSellLink(),
            const SizedBox(height: 10),
            _buildInspirationSection(),
            if (auth.isAuthenticated) ...[
              const SizedBox(height: 10),
              _buildLogout(auth),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── 1. Header ───────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    final notifCount = context.watch<NotificationProvider>().unreadCount;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Top row: title + icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mon EA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              Row(
                children: [
                  _HeaderIconBadge(
                    icon: Icons.notifications_outlined,
                    badgeCount: notifCount,
                    onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                  ),
                  const SizedBox(width: 16),
                  _HeaderIcon(
                    icon: Icons.qr_code_scanner,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QrScreen())),
                  ),
                  const SizedBox(width: 16),
                  _HeaderIcon(
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Avatar + name
          if (!auth.isAuthenticated) _buildLoginPrompt(context) else _buildUserInfo(auth),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.gray5,
            child: const Icon(Icons.person, size: 32, color: AppColors.gray3),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Se connecter / S\'inscrire',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connectez-vous pour accéder à votre compte',
                  style: TextStyle(fontSize: 12, color: AppColors.gray3),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gray4),
        ],
      ),
    );
  }

  Widget _buildUserInfo(AuthProvider auth) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.orange,
          child: Text(
            auth.userName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.userName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressesScreen())),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray3),
                    const SizedBox(width: 4),
                    Text(
                      'Ajouter une adresse de livraison',
                      style: TextStyle(fontSize: 12, color: AppColors.gray3),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.gray4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 2. Shortcut tiles ──────────────────────────────────────

  Widget _buildShortcutTiles() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          _ShortcutTile(
            icon: Icons.favorite_outline,
            label: 'Favoris',
            badge: _favoritesCount > 0 ? '$_favoritesCount article${_favoritesCount > 1 ? 's' : ''}' : null,
            onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
          ),
          // ✅ Bouton 2: Historique → BrowsingHistoryScreen
          _ShortcutTile(
            icon: Icons.access_time,
            label: 'Historique',
            onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BrowsingHistoryScreen()))),
          ),
          // ✅ Bouton 3: Coupons → CouponsScreen
          _ShortcutTile(
            icon: Icons.confirmation_number_outlined,
            label: 'Coupons',
            badge: _couponsCount > 0 ? '$_couponsCount coupon${_couponsCount > 1 ? 's' : ''}' : null,
            onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CouponsScreen()))),
          ),
        ],
      ),
    );
  }

  // ─── 3. Payment banner ──────────────────────────────────────

  Widget _buildPaymentBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF4FC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: AppColors.blue, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ajoutez un mode de paiement pour simplifier vos achats',
                style: TextStyle(fontSize: 13, color: AppColors.gray1),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray4, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── 4. Mes commandes ───────────────────────────────────────

  Widget _buildOrdersSection() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mes commandes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
              GestureDetector(
                onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()))),
                child: Row(
                  children: [
                    Text('Voir tout', style: TextStyle(fontSize: 13, color: AppColors.orange)),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.orange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Protection message
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gray6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toutes les commandes passées via EstuaireAchats sont protégées',
                    style: TextStyle(fontSize: 11, color: AppColors.gray2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Order status grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _OrderStatusItem(
                icon: Icons.pending_outlined,
                label: 'En attente',
                onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()))),
              ),
              _OrderStatusItem(
                icon: Icons.local_shipping_outlined,
                label: 'Expedie',
                onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()))),
              ),
              _OrderStatusItem(
                icon: Icons.check_circle_outline,
                label: 'Livre',
                onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()))),
              ),
              _OrderStatusItem(
                icon: Icons.replay,
                label: 'Retour',
                onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 5. Paiement & Financement ──────────────────────────────

  Widget _buildPaymentFinancing() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paiement & Financement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ✅ Bouton 8: Coupons & Credits → CouponsScreen
              _IconTile(
                icon: Icons.confirmation_number_outlined,
                label: 'Coupons &\nCrédits',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CouponsScreen())),
              ),
              // ✅ Bouton 9: Factures & Recus → InvoicesScreen
              _IconTile(
                icon: Icons.receipt_long_outlined,
                label: 'Factures &\nReçus',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoicesScreen())),
              ),
              // ✅ Bouton 10: Cartes & Comptes → WalletScreen
              _IconTile(
                icon: Icons.credit_card_outlined,
                label: 'Cartes &\nComptes',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
              _IconTile(
                icon: Icons.swap_horiz,
                label: 'Virement',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 6. Plus de fonctionnalites ─────────────────────────────

  Widget _buildMoreFeatures() {
    // ✅ Bouton 12: items null → dialogs ou ecrans corrects
    final features = [
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Portefeuille',
        'action': () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen()))),
      },
      {
        'icon': Icons.location_on_outlined,
        'label': "Adresse d'expédition",
        'action': () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressesScreen()))),
      },
      {
        'icon': Icons.article_outlined,
        'label': 'Infos fiscales',
        'action': () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaxInfoScreen()))),
      },
      {
        'icon': Icons.help_outline,
        'label': 'Demandes de renseignement',
        'action': () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen()))),
      },
      {
        'icon': Icons.card_membership,
        'label': 'Abonnement',
        'action': () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()))),
      },
      {
        'icon': Icons.request_quote_outlined,
        'label': 'Demandes de devis',
        'action': () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyQuotesScreen()))),
      },
      {
        'icon': Icons.verified_outlined,
        'label': 'Certificats',
        'action': () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CertificatesScreen()))),
      },
    ];

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plus de fonctionnalités',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: features.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = features[index];
                return GestureDetector(
                  onTap: f['action'] as VoidCallback,
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gray6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(f['icon'] as IconData, size: 24, color: AppColors.gray2),
                        const SizedBox(height: 6),
                        Text(
                          f['label'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.gray2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. Banniere parrainage ─────────────────────────────────

  Widget _buildReferralBanner() {
    return GestureDetector(
      // ✅ Bouton 4: Parrainage → ReferralScreen
      onTap: () => _requireAuth(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferralScreen()))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8C00), AppColors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Parrainez vos amis',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'et gagnez des coupons',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.share, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  // ─── 8. Banniere promo ──────────────────────────────────────

  Widget _buildPromoBanner() {
    return GestureDetector(
      // ✅ Bouton 5: Flash deals → FlashDealsScreen
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlashDealsScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gray5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.orange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Procurez-vous les articles préférés',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Retrouvez vos produits favoris à prix réduit',
                    style: TextStyle(fontSize: 11, color: AppColors.gray3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray4, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── 9. Agent de sourcing IA ────────────────────────────────

  Widget _buildAiSourcingLink() {
    return _LinkTile(
      icon: Icons.smart_toy_outlined,
      iconColor: AppColors.blue,
      label: 'Agent de sourcing par IA',
      subtitle: 'Trouvez des fournisseurs automatiquement',
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSourcingScreen())),
    );
  }

  // ─── 10. Commencez a vendre ─────────────────────────────────

  Widget _buildSellLink() {
    return _LinkTile(
      icon: Icons.storefront_outlined,
      iconColor: AppColors.green,
      label: 'Commencez à vendre sur EstuaireAchats',
      subtitle: 'Ouvrez votre boutique gratuitement',
      // ✅ Bouton 7: Vendre → dialog explicatif
      onTap: () => _showSellDialog(context),
    );
  }

  // ─── 11. Inspire de vos visites ─────────────────────────────

  Widget _buildInspirationSection() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspiré de vos visites',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 12),
          // Tabs
          Row(
            children: [
              _TabChip(
                label: 'Des favoris',
                isActive: _inspirationTab == 0,
                onTap: () => setState(() => _inspirationTab = 0),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Catégories',
                isActive: _inspirationTab == 1,
                onTap: () => setState(() => _inspirationTab = 1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Product grid
          if (_inspirationLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
            )
          else if (_inspirationProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Aucun produit disponible', style: TextStyle(color: AppColors.gray3, fontSize: 13))),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.55,
              ),
              itemCount: _inspirationTab == 0
                  ? _inspirationProducts.length.clamp(0, 6)
                  : _inspirationProducts.length.clamp(0, 4),
              itemBuilder: (context, index) {
                final products = _inspirationTab == 0
                    ? _inspirationProducts
                    : _inspirationProducts.reversed.toList();
                return ProductCard(product: products[index]);
              },
            ),
        ],
      ),
    );
  }

  // ─── 13. Logout ─────────────────────────────────────────────

  Widget _buildLogout(AuthProvider auth) {
    return Container(
      color: AppColors.white,
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppColors.red, size: 22),
        title: const Text(
          'Se déconnecter',
          style: TextStyle(fontSize: 14, color: AppColors.red, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.gray4, size: 20),
        onTap: () => auth.logout(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Private helper widgets
// ═══════════════════════════════════════════════════════════════

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 24, color: AppColors.dark),
    );
  }
}

class _HeaderIconBadge extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _HeaderIconBadge({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Badge(
        isLabelVisible: badgeCount > 0,
        label: Text(
          badgeCount > 99 ? '99+' : '$badgeCount',
          style: const TextStyle(fontSize: 8),
        ),
        child: Icon(icon, size: 24, color: AppColors.dark),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.gray6,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: AppColors.orange),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
              ),
              if (badge != null) ...[
                const SizedBox(height: 2),
                Text(
                  badge!,
                  style: const TextStyle(fontSize: 10, color: AppColors.gray3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _OrderStatusItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gray6,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: AppColors.gray1),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.gray2),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gray6,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: AppColors.gray1),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.gray2, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.gray3),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.gray4, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.orange : AppColors.gray6,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : AppColors.gray2,
          ),
        ),
      ),
    );
  }
}
