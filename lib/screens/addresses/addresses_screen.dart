import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'edit_address_screen.dart';

class _MockAddress {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String country;
  final bool isDefault;

  const _MockAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    this.isDefault = false,
  });
}

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final List<_MockAddress> _addresses = [
    const _MockAddress(
      id: '1',
      name: 'Jean-Paul Mbarga',
      phone: '+237 6 90 12 34 56',
      address: 'Rue de la Joie, Quartier Akwa',
      city: 'Douala',
      country: 'Cameroun',
      isDefault: true,
    ),
    const _MockAddress(
      id: '2',
      name: 'Jean-Paul Mbarga',
      phone: '+237 6 77 88 99 00',
      address: 'Avenue Kennedy, Quartier Bastos',
      city: 'Yaounde',
      country: 'Cameroun',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes adresses', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.orange),
            onPressed: () => _showAddressForm(context),
          ),
        ],
      ),
      body: _addresses.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildAddressCard(_addresses[index]),
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _showAddressForm(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Ajouter une adresse', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 64, color: AppColors.gray4),
          const SizedBox(height: 12),
          const Text('Aucune adresse enregistree', style: TextStyle(fontSize: 15, color: AppColors.gray3)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(_MockAddress address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: address.isDefault ? AppColors.orange.withOpacity(0.4) : AppColors.gray5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(address.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Par defaut', style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(address.phone, style: const TextStyle(fontSize: 13, color: AppColors.gray2)),
          const SizedBox(height: 4),
          Text(address.address, style: const TextStyle(fontSize: 13, color: AppColors.gray2)),
          Text('${address.city}, ${address.country}', style: const TextStyle(fontSize: 13, color: AppColors.gray2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  final addressData = AddressData(
                    id: address.id,
                    name: address.name,
                    phone: address.phone,
                    address: address.address,
                    city: address.city,
                    country: address.country,
                    isDefault: address.isDefault,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditAddressScreen(
                        address: addressData,
                        onSave: (updated) {
                          setState(() {
                            final idx = _addresses.indexWhere((a) => a.id == updated.id);
                            if (idx != -1) {
                              _addresses[idx] = _MockAddress(
                                id: updated.id,
                                name: updated.name,
                                phone: updated.phone,
                                address: updated.address,
                                city: updated.city,
                                country: updated.country,
                                isDefault: updated.isDefault,
                              );
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.gray3),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: const Text('Supprimer l\'adresse ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      content: Text(
                        'Voulez-vous supprimer l\'adresse de ${address.name} ?',
                        style: const TextStyle(fontSize: 14, color: AppColors.gray2),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler', style: TextStyle(color: AppColors.gray2)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _addresses.removeWhere((a) => a.id == address.id));
                          },
                          child: const Text('Supprimer', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddressForm(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController(text: '+237 ');
    final addressController = TextEditingController();
    String selectedCity = 'Douala';
    bool isDefault = false;

    final cities = ['Douala', 'Yaounde', 'Bafoussam', 'Bamenda', 'Garoua', 'Kribi', 'Limbe'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: AppColors.gray4, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nouvelle adresse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    _FormField(label: 'Nom complet', controller: nameController, hint: 'Jean-Paul Mbarga'),
                    const SizedBox(height: 14),
                    _FormField(label: 'Telephone', controller: phoneController, hint: '+237 6 XX XX XX XX', keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _FormField(label: 'Adresse', controller: addressController, hint: 'Rue, quartier, numero'),
                    const SizedBox(height: 14),
                    const Text('Ville', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.gray6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCity,
                          isExpanded: true,
                          items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                          onChanged: (v) => setSheetState(() => selectedCity = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Pays', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.gray6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Cameroun', style: TextStyle(fontSize: 14, color: AppColors.gray2)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (v) => setSheetState(() => isDefault = v!),
                          activeColor: AppColors.orange,
                        ),
                        const Text('Adresse par defaut', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Enregistrer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.gray6,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
