import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AddressData {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String country;
  final bool isDefault;

  const AddressData({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    this.isDefault = false,
  });
}

class EditAddressScreen extends StatefulWidget {
  final AddressData address;
  final void Function(AddressData updated) onSave;

  const EditAddressScreen({
    super.key,
    required this.address,
    required this.onSave,
  });

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late String _selectedCity;
  late bool _isDefault;

  final List<String> _cities = ['Douala', 'Yaounde', 'Bafoussam', 'Bamenda', 'Garoua', 'Kribi', 'Limbe'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address.name);
    _phoneController = TextEditingController(text: widget.address.phone);
    _addressController = TextEditingController(text: widget.address.address);
    _selectedCity = _cities.contains(widget.address.city) ? widget.address.city : _cities.first;
    _isDefault = widget.address.isDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final updated = AddressData(
      id: widget.address.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _selectedCity,
      country: widget.address.country,
      isDefault: _isDefault,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text('Modifier l\'adresse', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField('Nom complet', _nameController, hint: 'Jean-Paul Mbarga'),
                  const SizedBox(height: 14),
                  _buildField('Telephone', _phoneController, hint: '+237 6 XX XX XX XX', keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  _buildField('Adresse', _addressController, hint: 'Rue, quartier, numero'),
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
                        value: _selectedCity,
                        isExpanded: true,
                        items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _selectedCity = v!),
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
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v!),
                        activeColor: AppColors.orange,
                      ),
                      const Text('Adresse par defaut', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null,
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
