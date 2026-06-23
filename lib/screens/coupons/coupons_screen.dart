import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _api = ApiService();
  List<dynamic> _coupons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/coupons/me');
      setState(() {
        _coupons = (res.data is List) ? res.data as List<dynamic> : (res.data['data'] as List<dynamic>? ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Impossible de charger les coupons'; _loading = false; });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active': return AppColors.green;
      case 'used': return AppColors.gray3;
      case 'expired': return AppColors.primary;
      default: return AppColors.gray3;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active': return 'Actif';
      case 'used': return 'Utilise';
      case 'expired': return 'Expire';
      default: return status ?? '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text(
          'Mes Coupons',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.gray4),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.gray2)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadCoupons, child: const Text('Reessayer')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadCoupons,
                  child: _coupons.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.confirmation_number_outlined, size: 72, color: AppColors.gray4),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Aucun coupon disponible',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Vos coupons de reduction apparaitront ici',
                                    style: TextStyle(fontSize: 14, color: AppColors.gray3),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _coupons.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final coupon = _coupons[index] as Map<String, dynamic>;
                            final status = coupon['status'] as String?;
                            final isActive = status == 'active';
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.gray5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left decorative bar
                                  Container(
                                    width: 6,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: _statusColor(status),
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  coupon['code'] as String? ?? 'CODE',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.dark,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                              const SizedBox(width: 14),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            coupon['discountType'] == 'percentage'
                                                ? '-${coupon['discountValue']}%'
                                                : '-${coupon['discountValue']} FCFA',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: isActive ? AppColors.primary : AppColors.gray3,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.gray3),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Expire le ${_formatDate(coupon['expiresAt'] as String?)}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.gray3),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
