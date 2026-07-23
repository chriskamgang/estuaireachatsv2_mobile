import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../messaging/messaging_screen.dart';
import '../reviews/write_review_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ApiService().get('/orders/${widget.orderId}');
      final raw = res.data as Map<String, dynamic>;
      _order = raw.containsKey('data') ? (raw['data'] as Map<String, dynamic>?) ?? raw : raw;
      setState(() { _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Erreur de chargement de la commande'; });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy - HH:mm', 'fr_FR').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = _order?['orderNumber'] ?? widget.orderId;
    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #$orderNumber', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
                        onPressed: _loadOrderDetail,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                        child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildStatusTimeline(),
                    const SizedBox(height: 16),
                    _buildDeliveryTracking(),
                    const SizedBox(height: 16),
                    _buildDeliveryAddress(),
                    const SizedBox(height: 16),
                    _buildProductList(),
                    const SizedBox(height: 16),
                    _buildPriceBreakdown(),
                    const SizedBox(height: 16),
                    _buildPaymentMethod(),
                    const SizedBox(height: 24),
                    _buildActions(context),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Widget _buildStatusTimeline() {
    final status = (_order?['status'] ?? 'PENDING').toString().toUpperCase();
    final createdAt = _formatDate(_order?['createdAt']);
    final confirmedAt = _formatDate(_order?['confirmedAt']);
    final shippedAt = _formatDate(_order?['shippedAt']);
    final deliveredAt = _formatDate(_order?['deliveredAt']);

    final steps = <Map<String, dynamic>>[
      {'title': 'Commande passée', 'subtitle': createdAt.isNotEmpty ? createdAt : 'En attente', 'completed': true},
      {'title': 'Paiement confirmé', 'subtitle': confirmedAt.isNotEmpty ? confirmedAt : 'En attente', 'completed': ['CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED'].contains(status)},
      {'title': 'En préparation', 'subtitle': confirmedAt.isNotEmpty ? confirmedAt : 'En attente', 'completed': ['CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED'].contains(status)},
      {'title': 'Livreur en route', 'subtitle': status == 'PROCESSING' ? 'Merci E assigné' : (shippedAt.isNotEmpty ? shippedAt : 'En attente'), 'completed': ['PROCESSING', 'SHIPPED', 'DELIVERED'].contains(status)},
      {'title': 'En cours de livraison', 'subtitle': shippedAt.isNotEmpty ? shippedAt : 'En attente', 'completed': ['SHIPPED', 'DELIVERED'].contains(status)},
      {'title': 'Livré', 'subtitle': deliveredAt.isNotEmpty ? deliveredAt : 'En attente', 'completed': status == 'DELIVERED'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suivi de commande', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return _TimelineStep(
              title: step['title'],
              subtitle: step['subtitle'],
              isCompleted: step['completed'],
              isFirst: i == 0,
              isLast: i == steps.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeliveryTracking() {
    final status = (_order?['status'] ?? '').toString().toUpperCase();
    if (!['PROCESSING', 'SHIPPED', 'DELIVERED'].contains(status)) return const SizedBox.shrink();

    String statusTitle;
    String statusMessage;
    IconData statusIcon;
    Color statusColor;

    switch (status) {
      case 'PROCESSING':
        statusTitle = 'Livreur assigné';
        statusMessage = 'Un livreur Merci E est en route vers la boutique pour récupérer votre colis.';
        statusIcon = Icons.delivery_dining;
        statusColor = AppColors.orange;
        break;
      case 'SHIPPED':
        statusTitle = 'Colis en route';
        statusMessage = 'Votre colis a été récupéré et est en route vers vous.';
        statusIcon = Icons.local_shipping;
        statusColor = AppColors.blue;
        break;
      case 'DELIVERED':
        statusTitle = 'Livré';
        statusMessage = 'Votre colis a été livré avec succès.';
        statusIcon = Icons.check_circle;
        statusColor = AppColors.green;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 22, color: statusColor),
              const SizedBox(width: 10),
              Text(statusTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: statusColor)),
            ],
          ),
          const SizedBox(height: 10),
          Text(statusMessage, style: const TextStyle(fontSize: 13, color: AppColors.gray2, height: 1.4)),
          if (status == 'PROCESSING' || status == 'SHIPPED') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delivery_dining, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Livraison Merci E', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          status == 'PROCESSING'
                            ? 'Le livreur arrive bientôt à la boutique'
                            : 'Le livreur est en chemin vers vous',
                          style: const TextStyle(fontSize: 12, color: AppColors.gray3),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, color: AppColors.green, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    final address = (_order?['shippingAddress'] ?? _order?['address']) as Map<String, dynamic>?;
    final name = address?['name'] ?? address?['fullName'] ?? '';
    final phone = address?['phone'] ?? '';
    final street = address?['street'] ?? address?['address'] ?? '';
    final city = address?['city'] ?? '';
    final country = address?['country'] ?? 'Cameroun';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              const Text('Adresse de livraison', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          if (name.isNotEmpty)
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(phone, style: const TextStyle(fontSize: 13, color: AppColors.gray2)),
          ],
          const SizedBox(height: 4),
          Text(
            [street, city, country].where((s) => s.isNotEmpty).join('\n'),
            style: const TextStyle(fontSize: 13, color: AppColors.gray2, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final items = (_order?['details'] ?? _order?['items']) as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Articles commandés', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value as Map<String, dynamic>;
            final product = item['product'] as Map<String, dynamic>?;
            // Support both details format (name/image directly) and nested product format
            String imageUrl = item['image'] as String? ?? item['thumbnailUrl'] as String? ?? '';
            if (imageUrl.isEmpty) {
              final images = product?['images'] as List?;
              imageUrl = (images != null && images.isNotEmpty) ? (images[0]['url'] ?? '') : '';
            }
            final name = item['name'] as String? ?? item['productName'] as String? ?? product?['name'] ?? '';
            final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
            final price = (item['price'] as num?)?.toDouble() ?? (item['unitPrice'] as num?)?.toDouble() ?? 0;

            return Column(
              children: [
                if (i > 0) const Divider(height: 20),
                _ProductItem(
                  name: name,
                  image: imageUrl,
                  quantity: quantity,
                  price: price,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final total = (_order?['total'] as num?)?.toDouble() ?? 0;
    final shipping = (_order?['shippingCost'] as num?)?.toDouble() ?? 0;
    final subtotal = total - shipping;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'Sous-total', amount: subtotal > 0 ? subtotal : total),
          const SizedBox(height: 8),
          _PriceRow(label: 'Livraison', amount: shipping),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _PriceRow(label: 'Total', amount: total, isBold: true),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    final payment = _order?['paymentMethod'] as Map<String, dynamic>?;
    final method = payment?['type'] ?? _order?['paymentMethod'] ?? 'MTN Mobile Money';
    final methodStr = method is Map ? (method['type'] ?? 'MTN Mobile Money') : method.toString();
    final isMtn = methodStr.toString().toLowerCase().contains('mtn');
    final isOm = methodStr.toString().toLowerCase().contains('orange');

    final label = isMtn ? 'MTN' : (isOm ? 'OM' : 'Pay');
    final color = isMtn ? const Color(0xFFFFC107) : (isOm ? AppColors.orange : AppColors.blue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(methodStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(payment?['phone'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagingScreen()),
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Contacter le vendeur', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dark,
              side: const BorderSide(color: AppColors.gray4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WriteReviewScreen(orderId: widget.orderId),
              ),
            ),
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('Laisser un avis', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orange,
              side: const BorderSide(color: AppColors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.green : AppColors.gray4,
                    border: Border.all(
                      color: isCompleted ? AppColors.green : AppColors.gray4,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 10, color: AppColors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.green : AppColors.gray5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? AppColors.dark : AppColors.gray3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted ? AppColors.gray2 : AppColors.gray4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final String name;
  final String image;
  final int quantity;
  final double price;

  const _ProductItem({
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: image.isNotEmpty
              ? Image.network(
                  image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56, height: 56,
                    color: AppColors.gray5,
                    child: const Icon(Icons.image, color: AppColors.gray4, size: 20),
                  ),
                )
              : Container(
                  width: 56, height: 56,
                  color: AppColors.gray5,
                  child: const Icon(Icons.image, color: AppColors.gray4, size: 20),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('x$quantity', style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                  Text(formatPrice(price * quantity), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;

  const _PriceRow({required this.label, required this.amount, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: isBold ? 15 : 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          color: isBold ? AppColors.dark : AppColors.gray2,
        )),
        Text(formatPrice(amount), style: TextStyle(
          fontSize: isBold ? 16 : 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: isBold ? AppColors.orange : AppColors.dark,
        )),
      ],
    );
  }
}
