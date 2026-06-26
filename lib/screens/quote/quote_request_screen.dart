import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class QuoteRequestScreen extends StatefulWidget {
  const QuoteRequestScreen({super.key});

  @override
  State<QuoteRequestScreen> createState() => _QuoteRequestScreenState();
}

class _QuoteRequestScreenState extends State<QuoteRequestScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Categories from API
  bool _loadingCategories = true;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String _selectedCategoryName = '';

  // Step 1 - Produit
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedUnit = 'Pieces';

  // Step 2 - Details
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  String _selectedDelay = 'Flexible';
  final _deliveryLocationController = TextEditingController();

  // Step 3 - Contact
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();

  final List<XFile> _selectedImages = [];

  final _units = ['Pieces', 'Kg', 'Tonnes', 'Cartons', 'Metres'];
  final _delays = ['1 semaine', '2 semaines', '1 mois', '2 mois', 'Flexible'];

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _prefillUserInfo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _productNameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _deliveryLocationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await ApiService().get('/categories');
      final List data = res.data['data'] ?? [];
      final categories = data.map<Map<String, dynamic>>((c) => {
        'id': c['id']?.toString() ?? '',
        'name': c['name']?.toString() ?? '',
      }).toList();

      if (mounted) {
        setState(() {
          _categories = categories;
          if (categories.isNotEmpty) {
            _selectedCategoryId = categories.first['id'] as String;
            _selectedCategoryName = categories.first['name'] as String;
          }
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
  }

  void _prefillUserInfo() {
    try {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.user != null) {
        final user = auth.user!;
        final firstName = user['firstName'] ?? '';
        final lastName = user['lastName'] ?? '';
        _nameController.text = '$firstName $lastName'.trim();
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone'] ?? '';
      }
    } catch (_) {
      // Not critical if prefill fails
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitForm() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final detailsParts = <String>[
        'Produit: ${_productNameController.text.trim()}',
        if (_descriptionController.text.trim().isNotEmpty) 'Description: ${_descriptionController.text.trim()}',
        'Categorie: $_selectedCategoryName',
        'Quantite: ${_quantityController.text.trim()} $_selectedUnit',
        if (_budgetMinController.text.trim().isNotEmpty || _budgetMaxController.text.trim().isNotEmpty)
          'Budget: ${_budgetMinController.text.trim().isNotEmpty ? _budgetMinController.text.trim() : "?"} - ${_budgetMaxController.text.trim().isNotEmpty ? _budgetMaxController.text.trim() : "?"} FCFA',
        'Delai: $_selectedDelay',
        if (_deliveryLocationController.text.trim().isNotEmpty) 'Destination: ${_deliveryLocationController.text.trim()}',
        if (_companyController.text.trim().isNotEmpty) 'Entreprise: ${_companyController.text.trim()}',
        if (_messageController.text.trim().isNotEmpty) 'Message: ${_messageController.text.trim()}',
        'Contact: ${_nameController.text.trim()}, ${_emailController.text.trim()}${_phoneController.text.trim().isNotEmpty ? ", ${_phoneController.text.trim()}" : ""}',
      ];

      await ApiService().post('/rfq', data: {
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 1,
        'details': detailsParts.join('\n'),
      });

      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre demande de devis a été envoyée avec succès !'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi. Veuillez réessayer.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demande de devis', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final labels = ['Produit', 'Détails', 'Contact'];
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index <= _currentStep ? AppColors.orange : AppColors.gray5,
                    ),
                  ),
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppColors.orange : AppColors.gray5,
                      ),
                      child: Center(
                        child: index < _currentStep
                            ? const Icon(Icons.check, size: 16, color: AppColors.white)
                            : Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? AppColors.white : AppColors.gray3)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[index], style: TextStyle(fontSize: 11, color: isActive ? AppColors.orange : AppColors.gray3, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildLabel('Nom du produit'),
        const SizedBox(height: 6),
        _buildTextField(_productNameController, 'Ex: Écouteurs Bluetooth sans fil'),
        const SizedBox(height: 16),
        _buildLabel('Description détaillée'),
        const SizedBox(height: 6),
        _buildTextField(_descriptionController, 'Décrivez le produit souhaité...', maxLines: 4),
        const SizedBox(height: 16),
        _buildLabel('Catégorie'),
        const SizedBox(height: 6),
        if (_loadingCategories)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.gray6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Chargement des catégories...', style: TextStyle(fontSize: 14, color: AppColors.gray3)),
              ],
            ),
          )
        else if (_categories.isNotEmpty)
          _buildDropdown(
            value: _selectedCategoryName,
            items: _categories.map((c) => c['name'] as String).toList(),
            onChanged: (v) {
              final cat = _categories.firstWhere((c) => c['name'] == v);
              setState(() {
                _selectedCategoryName = v!;
                _selectedCategoryId = cat['id'] as String;
              });
            },
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.gray6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Aucune catégorie disponible', style: TextStyle(fontSize: 14, color: AppColors.gray3)),
          ),
        const SizedBox(height: 16),
        _buildLabel('Quantité souhaitée'),
        const SizedBox(height: 6),
        _buildTextField(_quantityController, 'Ex: 100', keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildLabel('Unité'),
        const SizedBox(height: 6),
        _buildDropdown(
          value: _selectedUnit,
          items: _units,
          onChanged: (v) => setState(() => _selectedUnit = v!),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildLabel('Budget estimé (FCFA)'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildTextField(_budgetMinController, 'Min', keyboardType: TextInputType.number)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('-', style: TextStyle(fontSize: 18, color: AppColors.gray3)),
            ),
            Expanded(child: _buildTextField(_budgetMaxController, 'Max', keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('Délai souhaité'),
        const SizedBox(height: 6),
        _buildDropdown(
          value: _selectedDelay,
          items: _delays,
          onChanged: (v) => setState(() => _selectedDelay = v!),
        ),
        const SizedBox(height: 16),
        _buildLabel('Lieu de livraison'),
        const SizedBox(height: 6),
        _buildTextField(_deliveryLocationController, 'Ex: Douala, Cameroun'),
        const SizedBox(height: 16),
        _buildLabel('Images de reference'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final images = await picker.pickMultiImage();
            if (images.isNotEmpty) {
              setState(() {
                _selectedImages.addAll(images);
              });
            }
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.gray6,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray4, style: BorderStyle.solid),
            ),
            child: _selectedImages.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.gray3),
                      const SizedBox(height: 8),
                      const Text('Appuyez pour ajouter des images de référence', style: TextStyle(fontSize: 13, color: AppColors.gray3)),
                      const Text('JPG, PNG (max 5 Mo)', style: TextStyle(fontSize: 11, color: AppColors.gray4)),
                    ],
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: _selectedImages.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == _selectedImages.length) {
                        return Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: AppColors.gray5,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: AppColors.gray3, size: 28),
                              SizedBox(height: 4),
                              Text('Ajouter', style: TextStyle(fontSize: 10, color: AppColors.gray3)),
                            ],
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              File(_selectedImages[i].path),
                              width: 100,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildLabel('Nom'),
        const SizedBox(height: 6),
        _buildTextField(_nameController, 'Votre nom complet'),
        const SizedBox(height: 16),
        _buildLabel('Email'),
        const SizedBox(height: 6),
        _buildTextField(_emailController, 'votre@email.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildLabel('Téléphone'),
        const SizedBox(height: 6),
        _buildTextField(_phoneController, '+237 6 XX XX XX XX', keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildLabel('Entreprise (optionnel)'),
        const SizedBox(height: 6),
        _buildTextField(_companyController, 'Nom de votre entreprise'),
        const SizedBox(height: 16),
        _buildLabel('Message supplémentaire'),
        const SizedBox(height: 6),
        _buildTextField(_messageController, 'Précisions supplémentaires...', maxLines: 4),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray5)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dark,
                  side: const BorderSide(color: AppColors.gray4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Précédent', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _submitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                    )
                  : Text(
                      _currentStep == 2 ? 'Envoyer la demande' : 'Suivant',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.gray6,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.gray3),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.gray6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
