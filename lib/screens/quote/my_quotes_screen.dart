import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../messaging/chat_screen.dart';
import 'quote_request_screen.dart';

class MyQuotesScreen extends StatefulWidget {
  const MyQuotesScreen({super.key});

  @override
  State<MyQuotesScreen> createState() => _MyQuotesScreenState();
}

class _MyQuotesScreenState extends State<MyQuotesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _quotes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService().get('/rfq');
      final List data = res.data['data'] ?? [];
      if (mounted) {
        setState(() {
          _quotes = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger vos demandes de devis.';
          _loading = false;
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppColors.orange;
      case 'QUOTED':
        return AppColors.blue;
      case 'ACCEPTED':
        return AppColors.green;
      case 'REJECTED':
        return AppColors.red;
      default:
        return AppColors.gray3;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'En attente';
      case 'QUOTED':
        return 'Devis recu';
      case 'ACCEPTED':
        return 'Accepte';
      case 'REJECTED':
        return 'Refuse';
      default:
        return status;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    final num value = price is num ? price : num.tryParse(price.toString()) ?? 0;
    return '${NumberFormat('#,###', 'fr_FR').format(value)} FCFA';
  }

  String _truncateDetails(String? details) {
    if (details == null || details.isEmpty) return 'Sans description';
    final firstLine = details.split('\n').first;
    if (firstLine.length > 60) return '${firstLine.substring(0, 60)}...';
    return firstLine;
  }

  void _showQuoteDetail(Map<String, dynamic> quote) {
    final status = (quote['status'] ?? 'PENDING').toString().toUpperCase();
    final details = quote['details']?.toString() ?? 'Aucun detail';
    final quantity = quote['quantity']?.toString() ?? '-';
    final quotedPrice = quote['quotedPrice'];
    final createdAt = _formatDate(quote['createdAt']?.toString());
    final conversationId = quote['conversationId']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Detail de la demande',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(status)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(createdAt, style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                    const SizedBox(width: 12),
                    Text('Qte: $quantity', style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Details
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details,
                        style: const TextStyle(fontSize: 14, color: AppColors.dark, height: 1.5),
                      ),
                      if (quotedPrice != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.green.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on_outlined, color: AppColors.green, size: 20),
                              const SizedBox(width: 10),
                              const Text('Prix propose : ', style: TextStyle(fontSize: 14, color: AppColors.dark)),
                              Text(
                                _formatPrice(quotedPrice),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Bottom actions
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.gray5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.dark,
                          side: const BorderSide(color: AppColors.gray4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Fermer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (status == 'QUOTED' && conversationId != null && conversationId.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  contactName: 'Vendeur',
                                  company: '',
                                  conversationId: conversationId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Voir la conversation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text('Mes demandes de devis', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _error != null
              ? _buildError()
              : _quotes.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuoteRequestScreen()),
          );
          _loadQuotes();
        },
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau devis', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray3),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.gray3)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadQuotes,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dark,
                side: const BorderSide(color: AppColors.gray4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.request_quote_outlined, size: 64, color: AppColors.gray4),
            const SizedBox(height: 16),
            const Text(
              'Aucune demande de devis',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Soumettez une demande de devis pour recevoir des offres de nos vendeurs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.gray3, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadQuotes,
      color: AppColors.orange,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _quotes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _buildQuoteCard(_quotes[index]),
      ),
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote) {
    final status = (quote['status'] ?? 'PENDING').toString().toUpperCase();
    final details = quote['details']?.toString();
    final quantity = quote['quantity']?.toString() ?? '-';
    final quotedPrice = quote['quotedPrice'];
    final createdAt = _formatDate(quote['createdAt']?.toString());

    return GestureDetector(
      onTap: () => _showQuoteDetail(quote),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gray5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: details + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _truncateDetails(details),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom row: quantity, date, price
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.gray3),
                const SizedBox(width: 4),
                Text('Qte: $quantity', style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.gray3),
                const SizedBox(width: 4),
                Text(createdAt, style: const TextStyle(fontSize: 12, color: AppColors.gray3)),
                const Spacer(),
                if (quotedPrice != null)
                  Text(
                    _formatPrice(quotedPrice),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
