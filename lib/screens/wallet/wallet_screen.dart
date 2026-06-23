import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _api = ApiService();
  double _balance = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _api.get('/wallet/balance'),
        _api.get('/wallet/history', params: {'perPage': 50}),
      ]);
      final balData = results[0].data;
      final histData = results[1].data;
      setState(() {
        _balance = (balData['data']?['balance'] ?? 0).toDouble();
        _transactions = List<Map<String, dynamic>>.from(histData['data'] ?? []);
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showRechargeSheet() {
    final amountController = TextEditingController();
    String method = 'MTN MoMo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recharger mon portefeuille',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 20),
                // Amount
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Montant (FCFA)',
                    hintText: 'Ex: 50000',
                    filled: true,
                    fillColor: AppColors.gray6,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Payment method
                const Text('Moyen de paiement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray1)),
                const SizedBox(height: 8),
                ...['MTN MoMo', 'Orange Money', 'PayPal'].map((m) => RadioListTile<String>(
                  title: Text(m, style: const TextStyle(fontSize: 14)),
                  value: m,
                  groupValue: method,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (v) => setSheetState(() => method = v!),
                )),
                const SizedBox(height: 12),
                // Confirm
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = int.tryParse(amountController.text);
                      if (amount == null || amount <= 0) return;
                      Navigator.pop(ctx);
                      await _handleRecharge(amount, method);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Confirmer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleRecharge(int amount, String method) async {
    try {
      final res = await _api.post('/wallet/recharge', data: {
        'amount': amount,
        'paymentMethod': method,
      });
      final newBalance = (res.data['data']?['newBalance'] ?? _balance + amount).toDouble();
      setState(() => _balance = newBalance);
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rechargement de ${formatPrice(amount)} effectue !'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du rechargement'), backgroundColor: AppColors.primary),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text('Mon portefeuille', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildQuickAmounts(),
                  const SizedBox(height: 24),
                  _buildTransactionList(),
                ],
              ),
            ),
    );
  }

  // ─── Balance Card ───────────────────────────────────────────

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.dark, Color(0xFF333333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.dark.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatPrice(_balance),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRechargeSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Recharger', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Amounts ──────────────────────────────────────────

  Widget _buildQuickAmounts() {
    const amounts = [5000, 10000, 25000, 50000];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recharge rapide', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
        const SizedBox(height: 10),
        Row(
          children: amounts.map((a) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: a != amounts.last ? 8 : 0),
              child: OutlinedButton(
                onPressed: () => _showRechargeSheet(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dark,
                  side: const BorderSide(color: AppColors.gray4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  '${(a / 1000).toInt()}K',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ─── Transaction List ───────────────────────────────────────

  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historique', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.gray4),
                  const SizedBox(height: 8),
                  const Text('Aucune transaction', style: TextStyle(color: AppColors.gray3, fontSize: 14)),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) => _buildTransactionTile(_transactions[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final amount = (tx['amount'] ?? 0).toDouble();
    final isCredit = amount > 0;
    final note = tx['note'] ?? '-';
    final method = tx['paymentMethod'] ?? '';
    final date = tx['createdAt'] != null
        ? DateTime.tryParse(tx['createdAt'].toString())
        : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCredit ? AppColors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: isCredit ? AppColors.green : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        note,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        date != null ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • $method' : method,
        style: const TextStyle(fontSize: 11, color: AppColors.gray3),
      ),
      trailing: Text(
        '${isCredit ? '+' : ''}${formatPrice(amount.abs())}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isCredit ? AppColors.green : AppColors.primary,
        ),
      ),
    );
  }
}
