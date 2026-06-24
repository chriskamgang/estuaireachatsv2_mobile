import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  List<dynamic> _allCoupons = [];
  List<dynamic> _loyaltyCoupons = [];
  bool _loadingAll = true;
  bool _loadingLoyalty = true;
  String? _errorAll;
  String? _errorLoyalty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllCoupons();
    _loadLoyaltyCoupons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCoupons() async {
    setState(() {
      _loadingAll = true;
      _errorAll = null;
    });
    try {
      final res = await _api.get('/coupons/me');
      setState(() {
        _allCoupons = (res.data is List)
            ? res.data as List<dynamic>
            : (res.data['data'] as List<dynamic>? ?? []);
        _loadingAll = false;
      });
    } catch (e) {
      setState(() {
        _errorAll = 'Impossible de charger les coupons';
        _loadingAll = false;
      });
    }
  }

  Future<void> _loadLoyaltyCoupons() async {
    setState(() {
      _loadingLoyalty = true;
      _errorLoyalty = null;
    });
    try {
      final res = await _api.get('/coupons/me/loyalty');
      setState(() {
        _loyaltyCoupons = (res.data is List)
            ? res.data as List<dynamic>
            : (res.data['data'] as List<dynamic>? ?? []);
        _loadingLoyalty = false;
      });
    } catch (e) {
      setState(() {
        _errorLoyalty = 'Impossible de charger les coupons fidelite';
        _loadingLoyalty = false;
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return AppColors.green;
      case 'used':
        return AppColors.gray3;
      case 'expired':
        return AppColors.primary;
      default:
        return AppColors.gray3;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'used':
        return 'Utilise';
      case 'expired':
        return 'Expire';
      default:
        return status ?? '';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: AppColors.white, size: 18),
            SizedBox(width: 8),
            Text('Code copie !'),
          ],
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text(
          'Mes Coupons',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray3,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Fidelite'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet "Tous"
          _buildCouponsList(
            coupons: _allCoupons,
            loading: _loadingAll,
            error: _errorAll,
            onRefresh: _loadAllCoupons,
            isLoyaltyTab: false,
          ),
          // Onglet "Fidelite"
          _buildCouponsList(
            coupons: _loyaltyCoupons,
            loading: _loadingLoyalty,
            error: _errorLoyalty,
            onRefresh: _loadLoyaltyCoupons,
            isLoyaltyTab: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsList({
    required List<dynamic> coupons,
    required bool loading,
    required String? error,
    required Future<void> Function() onRefresh,
    required bool isLoyaltyTab,
  }) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray4),
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: AppColors.gray2)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRefresh, child: const Text('Reessayer')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: coupons.isEmpty
          ? ListView(
              children: [
                if (isLoyaltyTab) _buildLoyaltyProgramBanner(),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isLoyaltyTab
                            ? Icons.card_giftcard_outlined
                            : Icons.confirmation_number_outlined,
                        size: 72,
                        color: AppColors.gray4,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isLoyaltyTab
                            ? 'Pas encore de coupon fidelite'
                            : 'Aucun coupon disponible',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          isLoyaltyTab
                              ? 'Continuez vos achats pour gagner des coupons de fidelite !'
                              : 'Vos coupons de reduction apparaitront ici',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.gray3),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: coupons.length + (isLoyaltyTab ? 1 : 0),
              itemBuilder: (context, index) {
                if (isLoyaltyTab && index == 0) {
                  return _buildLoyaltyProgramBanner();
                }
                final couponIndex = isLoyaltyTab ? index - 1 : index;
                final coupon = coupons[couponIndex] as Map<String, dynamic>;
                return _buildCouponCard(coupon, isLoyaltyTab: isLoyaltyTab);
              },
            ),
    );
  }

  Widget _buildLoyaltyProgramBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.green,
            AppColors.green.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.loyalty, color: AppColors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Programme Fidelite',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tous les 5 achats, recevez un coupon de reduction !',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon,
      {bool isLoyaltyTab = false}) {
    final status = coupon['status'] as String?;
    final isActive = status == 'active';
    final code = coupon['code'] as String? ?? 'CODE';
    final discountType = coupon['discountType'] as String?;
    final discountValue = coupon['discountValue'];
    final expiresAt = coupon['expiresAt'] as String?;
    final type = coupon['type'] as String?;
    final isLoyalty = isLoyaltyTab || type == 'loyalty';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? (isLoyalty
                  ? AppColors.green.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.3))
              : AppColors.gray5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Barre decorative gauche
              Container(
                width: 6,
                height: 120,
                decoration: BoxDecoration(
                  color: isLoyalty ? AppColors.green : _statusColor(status),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne 1 : badges
                      Row(
                        children: [
                          // Badge statut
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(status),
                              ),
                            ),
                          ),
                          if (isLoyalty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.loyalty,
                                      size: 10, color: AppColors.green),
                                  SizedBox(width: 3),
                                  Text(
                                    'Fidelite',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Ligne 2 : reduction en gros
                      Text(
                        discountType == 'percentage'
                            ? '-$discountValue%'
                            : '-$discountValue FCFA',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? (isLoyalty ? AppColors.green : AppColors.primary)
                              : AppColors.gray3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Ligne 3 : code coupon avec bouton copier
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.gray6,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyCode(code),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.gray6,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.copy,
                                size: 16,
                                color: AppColors.gray2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Ligne 4 : date d'expiration
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppColors.gray3),
                          const SizedBox(width: 4),
                          Text(
                            'Expire le ${_formatDate(expiresAt)}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.gray3),
                          ),
                        ],
                      ),
                      // Ligne 5 : message motivant pour fidelite
                      if (isLoyalty && isActive) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_outlined,
                                size: 14, color: AppColors.green),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text(
                                'Bravo ! Coupon gagne grace a vos achats.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
