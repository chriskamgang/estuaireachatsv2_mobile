import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ApiService().get('/orders', params: {'page': 1, 'perPage': 20});
      final data = res.data;
      final List list = data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
      _orders = list.cast<Map<String, dynamic>>();
      setState(() { _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Erreur de chargement des commandes'; });
    }
  }

  String _mapApiStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'enAttente';
      case 'CONFIRMED': return 'enAttente';
      case 'PROCESSING': return 'expedie';
      case 'SHIPPED': return 'expedie';
      case 'DELIVERED': return 'livre';
      case 'CANCELLED': return 'annule';
      default: return 'enAttente';
    }
  }

  List<Map<String, dynamic>> _filterByStatus(String? statusKey) {
    if (statusKey == null) return _orders;
    return _orders.where((o) => _mapApiStatus(o['status'] ?? '') == statusKey).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes commandes', style: TextStyle(fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.gray3,
            indicatorColor: AppColors.orange,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Tous'),
              Tab(text: 'En attente'),
              Tab(text: 'Expédié'),
              Tab(text: 'Livré'),
              Tab(text: 'Retours'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.gray2, fontSize: 15)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                          child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _OrderList(orders: _filterByStatus(null)),
                      _OrderList(orders: _filterByStatus('enAttente')),
                      _OrderList(orders: _filterByStatus('expedie')),
                      _OrderList(orders: _filterByStatus('livre')),
                      _OrderList(orders: _filterByStatus('annule')),
                    ],
                  ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.gray4),
            const SizedBox(height: 12),
            const Text('Aucune commande', style: TextStyle(color: AppColors.gray3, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  String get _orderNumber => order['orderNumber'] ?? '';
  String get _status => (order['status'] ?? 'PENDING').toString().toUpperCase();
  double get _total => (order['total'] as num?)?.toDouble() ?? 0;
  String get _shopName => (order['shop'] as Map?)?['name'] ?? '';

  String get _date {
    try {
      final dt = DateTime.parse(order['createdAt'] ?? '');
      return DateFormat('dd MMM yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return order['createdAt'] ?? '';
    }
  }

  // Get first item info for display
  Map<String, dynamic>? get _firstItem {
    final items = order['items'] as List?;
    if (items == null || items.isEmpty) return null;
    return items[0] as Map<String, dynamic>;
  }

  String get _productName {
    final item = _firstItem;
    if (item == null) return '';
    final product = item['product'] as Map<String, dynamic>?;
    return product?['name'] ?? '';
  }

  String get _productImage {
    final item = _firstItem;
    if (item == null) return '';
    final product = item['product'] as Map<String, dynamic>?;
    final images = product?['images'] as List?;
    if (images == null || images.isEmpty) return '';
    return images[0]['url'] ?? '';
  }

  int get _totalQuantity {
    final items = order['items'] as List? ?? [];
    int total = 0;
    for (final item in items) {
      total += ((item as Map)['quantity'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_orderNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                _StatusBadge(status: _status),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _productImage.isNotEmpty
                      ? Image.network(
                          _productImage,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64, height: 64,
                            color: AppColors.gray5,
                            child: const Icon(Icons.image, color: AppColors.gray4),
                          ),
                        )
                      : Container(
                          width: 64, height: 64,
                          color: AppColors.gray5,
                          child: const Icon(Icons.image, color: AppColors.gray4),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(_shopName, style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Qté: $_totalQuantity', style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                          Text(formatPrice(_total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.orange)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_date, style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order['id'] ?? '')),
                  ),
                  child: const Text('Voir détails', style: TextStyle(fontSize: 13, color: AppColors.orange, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'PENDING' || 'CONFIRMED' => ('En attente', AppColors.orange),
      'PROCESSING' => ('En livraison', AppColors.blue),
      'SHIPPED' => ('Expédié', AppColors.blue),
      'DELIVERED' => ('Livré', AppColors.green),
      'CANCELLED' => ('Annulé', AppColors.red),
      _ => ('En attente', AppColors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
