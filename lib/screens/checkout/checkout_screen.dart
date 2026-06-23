import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/cart_provider.dart';
import '../main_screen.dart';
import '../addresses/addresses_screen.dart';

enum DeliveryMethod { standard, express }

enum PaymentMethod { mtnMomo, orangeMoney, paypal }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1 - Adresse
  DeliveryMethod _deliveryMethod = DeliveryMethod.standard;
  bool _loadingAddress = true;
  Map<String, dynamic>? _defaultAddress;
  String? _addressError;

  // Step 2 - Paiement
  PaymentMethod _paymentMethod = PaymentMethod.mtnMomo;
  final TextEditingController _phoneController = TextEditingController(text: '');

  // Step 3 - Confirmation
  bool _submitting = false;

  // Step labels
  final List<String> _stepLabels = ['Adresse', 'Paiement', 'Confirmation'];

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultAddress() async {
    setState(() {
      _loadingAddress = true;
      _addressError = null;
    });

    try {
      final res = await ApiService().get('/addresses');
      final List data = res.data['data'] ?? [];
      if (data.isNotEmpty) {
        // Find default address or use first one
        final defaultAddr = data.firstWhere(
          (a) => a['isDefault'] == true,
          orElse: () => data.first,
        );
        setState(() {
          _defaultAddress = Map<String, dynamic>.from(defaultAddr);
          _loadingAddress = false;
        });
      } else {
        setState(() {
          _defaultAddress = null;
          _loadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingAddress = false;
        _addressError = 'Impossible de charger les adresses';
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmOrder();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  double _getDeliveryFee() {
    return _deliveryMethod == DeliveryMethod.express ? 3500 : 1500;
  }

  Future<void> _confirmOrder() async {
    if (_submitting) return;

    final cart = context.read<CartProvider>();
    final selectedItems = cart.items.where((i) => i.selected).toList();
    if (selectedItems.isEmpty) return;

    setState(() => _submitting = true);

    try {
      // Determine payment method string
      String paymentMethodStr;
      switch (_paymentMethod) {
        case PaymentMethod.mtnMomo:
          paymentMethodStr = 'mtn_momo';
          break;
        case PaymentMethod.orangeMoney:
          paymentMethodStr = 'orange_money';
          break;
        case PaymentMethod.paypal:
          paymentMethodStr = 'paypal';
          break;
      }

      // Create order
      final orderRes = await ApiService().post('/orders', data: {
        'addressId': _defaultAddress?['id'],
        'deliveryMethod': _deliveryMethod == DeliveryMethod.express ? 'express' : 'standard',
        'paymentMethod': paymentMethodStr,
        'phone': _phoneController.text,
        'items': selectedItems.map((item) => {
          'productId': item.id,
          'quantity': item.quantity,
        }).toList(),
      });

      final orderId = orderRes.data['data']?['id'];
      final orderNumber = orderRes.data['data']?['orderNumber'] ?? 'EA-${100000 + Random().nextInt(900000)}';

      // Init payment if not PayPal
      if (_paymentMethod != PaymentMethod.paypal && orderId != null) {
        try {
          await ApiService().post('/payments/init', data: {
            'orderId': orderId,
            'method': paymentMethodStr,
            'phone': '237${_phoneController.text}',
          });
        } catch (_) {
          // Payment init can fail silently, order was already created
        }
      }

      if (!mounted) return;
      setState(() => _submitting = false);

      _showSuccessDialog(orderNumber.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la création de la commande. Veuillez réessayer.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(String orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Commande confirmee !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre commande a été passée avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.gray2),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gray6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long, size: 18, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'N° $orderNumber',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous recevrez un SMS de confirmation.',
                style: TextStyle(fontSize: 12, color: AppColors.gray3),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CartProvider>().clear();
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Continuer mes achats',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final totalWithDelivery = cart.total + _getDeliveryFee();

    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Paiement',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildStepIndicator(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildAddressStep(),
          _buildPaymentStep(),
          _buildConfirmationStep(cart),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(cart, totalWithDelivery),
    );
  }

  // --- Step Indicator ---

  Widget _buildStepIndicator() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index <= _currentStep
                          ? AppColors.orange
                          : AppColors.gray4,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.orange : AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? AppColors.orange : AppColors.gray4,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: index < _currentStep
                            ? const Icon(Icons.check, size: 14, color: AppColors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? AppColors.white : AppColors.gray3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepLabels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? AppColors.orange : AppColors.gray3,
                      ),
                    ),
                  ],
                ),
                if (index < 2 && index == 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index + 1 <= _currentStep
                          ? AppColors.orange
                          : AppColors.gray4,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- Coupon Sheet ---

  void _showCouponSheet() {
    final couponController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.gray4, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ajouter un coupon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: couponController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Ex: PROMO20',
                filled: true,
                fillColor: AppColors.gray6,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                prefixIcon: const Icon(Icons.local_offer_outlined, color: AppColors.orange, size: 20),
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        couponController.text.trim().isEmpty
                            ? 'Veuillez entrer un code coupon'
                            : 'Code coupon "${couponController.text.trim()}" - Fonctionnalité bientôt disponible',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Appliquer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Adresse de livraison ---

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address card
          if (_loadingAddress)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray5),
              ),
              child: const Center(child: CircularProgressIndicator(color: AppColors.orange)),
            )
          else if (_addressError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray5),
              ),
              child: Column(
                children: [
                  Text(_addressError!, style: const TextStyle(fontSize: 14, color: AppColors.gray2)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadDefaultAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (_defaultAddress == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.orange, width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_off_outlined, size: 48, color: AppColors.gray4),
                  const SizedBox(height: 12),
                  const Text(
                    'Ajoutez une adresse de livraison',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray2),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddressesScreen()),
                      );
                      _loadDefaultAddress();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter une adresse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildAddressCard(),

          const SizedBox(height: 20),

          // Delivery method
          const Text(
            'Mode de livraison',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 10),
          _buildDeliveryOption(
            method: DeliveryMethod.standard,
            title: 'Livraison standard',
            subtitle: '3 - 5 jours ouvrables',
            price: 1500,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 8),
          _buildDeliveryOption(
            method: DeliveryMethod.express,
            title: 'Livraison express',
            subtitle: '1 - 2 jours ouvrables',
            price: 3500,
            icon: Icons.rocket_launch_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final addr = _defaultAddress!;
    final fullName = addr['fullName'] ?? '';
    final phone = addr['phone'] ?? '';
    final address = addr['address'] ?? '';
    final city = addr['city'] ?? '';
    final country = addr['country'] ?? 'Cameroun';
    final isDefault = addr['isDefault'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.orange, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Adresse de livraison',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Par défaut',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: AppColors.gray2),
              const SizedBox(width: 6),
              Text(
                phone,
                style: TextStyle(fontSize: 13, color: AppColors.gray2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.home_outlined, size: 14, color: AppColors.gray2),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$address\n$city, $country',
                  style: TextStyle(fontSize: 13, color: AppColors.gray2, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddressesScreen()),
                    );
                    _loadDefaultAddress();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Modifier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dark,
                    side: const BorderSide(color: AppColors.gray4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCouponSheet(),
                  icon: const Icon(Icons.local_offer_outlined, size: 16),
                  label: const Text('Coupon'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: const BorderSide(color: AppColors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required DeliveryMethod method,
    required String title,
    required String subtitle,
    required double price,
    required IconData icon,
  }) {
    final isSelected = _deliveryMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = method),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.orange : AppColors.gray5,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.orange : AppColors.gray3,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.gray3),
                  ),
                ],
              ),
            ),
            Text(
              formatPrice(price),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.orange : AppColors.dark,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.orange : AppColors.gray4,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Mode de paiement ---

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisir un mode de paiement',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),

          // MTN Mobile Money
          _buildPaymentOption(
            method: PaymentMethod.mtnMomo,
            title: 'MTN Mobile Money',
            subtitle: 'Payez avec votre compte MoMo',
            icon: Icons.phone_android,
            accentColor: const Color(0xFFFFC107),
          ),
          const SizedBox(height: 8),

          // Orange Money
          _buildPaymentOption(
            method: PaymentMethod.orangeMoney,
            title: 'Orange Money',
            subtitle: 'Payez avec Orange Money',
            icon: Icons.phone_android,
            accentColor: AppColors.orange,
          ),
          const SizedBox(height: 8),

          // PayPal
          _buildPaymentOption(
            method: PaymentMethod.paypal,
            title: 'PayPal',
            subtitle: 'Paiement international securise',
            icon: Icons.payment,
            accentColor: AppColors.blue,
          ),

          const SizedBox(height: 20),

          // Phone input for Mobile Money
          if (_paymentMethod == PaymentMethod.mtnMomo ||
              _paymentMethod == PaymentMethod.orangeMoney) ...[
            const Text(
              'Numero de telephone',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.gray6,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: AppColors.gray4, width: 0.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 6, color: const Color(0xFF009639)),
                              Container(height: 7, color: const Color(0xFFCE1126)),
                              Container(height: 6, color: const Color(0xFFFCD116)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '+237',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      decoration: const InputDecoration(
                        hintText: '6XX XXX XXX',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _paymentMethod == PaymentMethod.mtnMomo
                  ? 'Entrez votre numero MTN MoMo pour recevoir la demande de paiement.'
                  : 'Entrez votre numero Orange Money pour recevoir la demande de paiement.',
              style: TextStyle(fontSize: 12, color: AppColors.gray3),
            ),
          ],

          // PayPal redirect message
          if (_paymentMethod == PaymentMethod.paypal) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vous serez redirigé vers PayPal pour finaliser le paiement en toute sécurité.',
                      style: TextStyle(fontSize: 13, color: AppColors.blue, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Security badges
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vos informations de paiement sont protégées par un chiffrement SSL 256 bits.',
                    style: TextStyle(fontSize: 11, color: AppColors.gray2, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.gray5,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 22, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.gray3),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? accentColor : AppColors.gray4,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 3: Confirmation ---

  Widget _buildConfirmationStep(CartProvider cart) {
    final deliveryFee = _getDeliveryFee();
    final grandTotal = cart.total + deliveryFee;

    final addr = _defaultAddress;
    final addrName = addr?['fullName'] ?? 'Adresse non définie';
    final addrPhone = addr?['phone'] ?? '';
    final addrLine = [
      addr?['address'] ?? '',
      addr?['city'] ?? '',
      addr?['country'] ?? '',
    ].where((s) => s.isNotEmpty).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order items
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.dark),
                    const SizedBox(width: 8),
                    Text(
                      'Résumé de la commande (${cart.items.where((i) => i.selected).length} articles)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...cart.items.where((i) => i.selected).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.image,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.gray5,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.image_outlined, size: 20, color: AppColors.gray3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppColors.dark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Qté: ${item.quantity}',
                              style: TextStyle(fontSize: 11, color: AppColors.gray3),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatPrice(item.price * item.quantity),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Price breakdown
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildPriceRow('Sous-total', formatPrice(cart.total)),
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Livraison (${_deliveryMethod == DeliveryMethod.express ? 'Express' : 'Standard'})',
                  formatPrice(deliveryFee),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    Text(
                      formatPrice(grandTotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Delivery address summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.gray2),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$addrName${addrPhone.isNotEmpty ? '  -  $addrPhone' : ''}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        addrLine,
                        style: TextStyle(fontSize: 12, color: AppColors.gray3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Payment method summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _paymentMethod == PaymentMethod.paypal
                      ? Icons.payment
                      : Icons.phone_android,
                  size: 18,
                  color: AppColors.gray2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _paymentMethodLabel(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Buyer protection
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, size: 22, color: AppColors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Protection acheteur',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Remboursement garanti si votre commande n\'est pas livrée ou ne correspond pas à la description.',
                        style: TextStyle(fontSize: 11, color: AppColors.gray2, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _paymentMethodLabel() {
    switch (_paymentMethod) {
      case PaymentMethod.mtnMomo:
        final phone = _phoneController.text.isNotEmpty
            ? ' (+237 ${_phoneController.text})'
            : '';
        return 'MTN Mobile Money$phone';
      case PaymentMethod.orangeMoney:
        final phone = _phoneController.text.isNotEmpty
            ? ' (+237 ${_phoneController.text})'
            : '';
        return 'Orange Money$phone';
      case PaymentMethod.paypal:
        return 'PayPal';
    }
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.gray2)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
      ],
    );
  }

  // --- Bottom Bar ---

  Widget _buildBottomBar(CartProvider cart, double totalWithDelivery) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontSize: 12, color: AppColors.gray3),
                ),
                const SizedBox(height: 2),
                Text(
                  formatPrice(totalWithDelivery),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: (cart.isEmpty || _submitting || (_currentStep == 0 && _defaultAddress == null))
                  ? null
                  : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 2 ? AppColors.green : AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                    )
                  : Text(
                      _currentStep == 2 ? 'Confirmer la commande' : 'Suivant',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
