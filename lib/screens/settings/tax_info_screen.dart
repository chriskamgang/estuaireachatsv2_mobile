import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TaxInfoScreen extends StatefulWidget {
  const TaxInfoScreen({super.key});

  @override
  State<TaxInfoScreen> createState() => _TaxInfoScreenState();
}

class _TaxInfoScreenState extends State<TaxInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taxIdController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _rccmController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _taxIdController.dispose();
    _companyNameController.dispose();
    _rccmController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations fiscales enregistrees'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infos fiscales', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.orange, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Ces informations sont necessaires pour la facturation et les declarations fiscales.',
                      style: TextStyle(fontSize: 12, color: AppColors.gray1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Numero contribuable (NIU)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _taxIdController,
              decoration: _inputDecoration('Ex: M012345678901A'),
              validator: (v) => v != null && v.isNotEmpty ? null : 'Champ requis',
            ),
            const SizedBox(height: 16),
            _buildLabel('Raison sociale'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _companyNameController,
              decoration: _inputDecoration('Nom de votre entreprise'),
              validator: (v) => v != null && v.isNotEmpty ? null : 'Champ requis',
            ),
            const SizedBox(height: 16),
            _buildLabel('Numero RCCM (optionnel)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _rccmController,
              decoration: _inputDecoration('Ex: RC/DLA/2024/A/001'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Adresse du siege social'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: _inputDecoration('Adresse complete'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.gray6,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.gray3),
    );
  }
}
