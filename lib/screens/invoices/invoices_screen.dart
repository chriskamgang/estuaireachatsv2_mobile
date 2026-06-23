import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/orders', params: {'perPage': 50});
      final data = res.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = (data['data'] as List<dynamic>?) ?? (data['orders'] as List<dynamic>?) ?? [];
      }
      setState(() { _orders = list; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Impossible de charger les factures'; _loading = false; });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'delivered': return AppColors.green;
      case 'shipped': return AppColors.secondary;
      case 'pending': return const Color(0xFFFF8C00);
      case 'cancelled': return AppColors.primary;
      default: return AppColors.gray3;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'delivered': return 'Livre';
      case 'shipped': return 'Expedie';
      case 'pending': return 'En attente';
      case 'processing': return 'En traitement';
      case 'cancelled': return 'Annule';
      default: return status ?? 'Inconnu';
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
          'Factures & Recus',
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
                      ElevatedButton(onPressed: _loadOrders, child: const Text('Reessayer')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadOrders,
                  child: _orders.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 72, color: AppColors.gray4),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Aucune facture',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Vos factures et recus apparaitront ici\napres vos premieres commandes',
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
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final order = _orders[index] as Map<String, dynamic>;
                            final orderNumber = order['orderNumber'] as String? ?? order['id']?.toString() ?? '#${index + 1}';
                            final total = (order['total'] as num?)?.toDouble() ?? (order['totalAmount'] as num?)?.toDouble() ?? 0;
                            final status = order['status'] as String?;
                            final createdAt = order['createdAt'] as String?;
                            final itemsCount = (order['items'] as List?)?.length ?? (order['orderItems'] as List?)?.length ?? 0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray6,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.receipt_outlined, color: AppColors.gray2, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Commande $orderNumber',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.dark,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${_formatDate(createdAt)} • $itemsCount article${itemsCount > 1 ? 's' : ''}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.gray3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatPrice(total),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
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
                                    ],
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
