import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:estuaire_achats/core/theme.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  // Prix
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  // MOQ
  int? _selectedMoqIndex;
  final _moqOptions = ['1+', '10+', '50+', '100+', '500+', '1000+'];

  // Fournisseur verifie
  bool _verifiedOnly = false;

  // Annees d'experience
  int? _selectedExpIndex;
  final _expOptions = ['1+ ans', '3+ ans', '5+ ans', '10+ ans'];

  // Livraison
  int? _selectedDeliveryIndex;
  final _deliveryOptions = ['Locale (Cameroun)', 'Afrique', 'International'];

  // Pays d'origine
  final _countryOptions = ['Chine', 'Cameroun', 'Nigeria', 'Turquie', 'Inde', 'Autre'];
  final Set<String> _selectedCountries = {};

  // Certifications
  final _certOptions = ['CE', 'ISO', 'SGS', 'BSCI'];
  final Set<String> _selectedCerts = {};

  // Tri par
  int _selectedSortIndex = 0;
  final _sortOptions = [
    'Pertinence',
    'Prix croissant',
    'Prix decroissant',
    'Plus vendus',
    'Plus recents',
  ];

  // Mock result count
  final int _resultCount = 234;

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedMoqIndex = null;
      _verifiedOnly = false;
      _selectedExpIndex = null;
      _selectedDeliveryIndex = null;
      _selectedCountries.clear();
      _selectedCerts.clear();
      _selectedSortIndex = 0;
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Filtres',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Réinitialiser',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: AppColors.gray5),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceSection(),
                  const SizedBox(height: 28),
                  _buildMoqSection(),
                  const SizedBox(height: 28),
                  _buildVerifiedSection(),
                  const SizedBox(height: 28),
                  _buildExperienceSection(),
                  const SizedBox(height: 28),
                  _buildDeliverySection(),
                  const SizedBox(height: 28),
                  _buildCountrySection(),
                  const SizedBox(height: 28),
                  _buildCertSection(),
                  const SizedBox(height: 28),
                  _buildSortSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section title
  // ---------------------------------------------------------------------------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Prix (FCFA)
  // ---------------------------------------------------------------------------
  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Prix (FCFA)'),
        Row(
          children: [
            Expanded(child: _PriceField(controller: _minPriceController, hint: 'Min')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('—', style: TextStyle(color: AppColors.gray3, fontSize: 16)),
            ),
            Expanded(child: _PriceField(controller: _maxPriceController, hint: 'Max')),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Quantite minimum (MOQ)
  // ---------------------------------------------------------------------------
  Widget _buildMoqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Quantité minimum (MOQ)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_moqOptions.length, (i) {
            final selected = _selectedMoqIndex == i;
            return _FilterChip(
              label: _moqOptions[i],
              selected: selected,
              onTap: () => setState(() {
                _selectedMoqIndex = selected ? null : i;
              }),
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Fournisseur verifie
  // ---------------------------------------------------------------------------
  Widget _buildVerifiedSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fournisseur vérifié',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Fournisseurs vérifiés uniquement',
                style: TextStyle(fontSize: 13, color: AppColors.gray3),
              ),
            ],
          ),
        ),
        Switch(
          value: _verifiedOnly,
          onChanged: (v) => setState(() => _verifiedOnly = v),
          activeColor: AppColors.orange,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Annees d'experience
  // ---------------------------------------------------------------------------
  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Années d'expérience"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_expOptions.length, (i) {
            final selected = _selectedExpIndex == i;
            return _FilterChip(
              label: _expOptions[i],
              selected: selected,
              onTap: () => setState(() {
                _selectedExpIndex = selected ? null : i;
              }),
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Livraison
  // ---------------------------------------------------------------------------
  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Livraison'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_deliveryOptions.length, (i) {
            final selected = _selectedDeliveryIndex == i;
            return _FilterChip(
              label: _deliveryOptions[i],
              selected: selected,
              onTap: () => setState(() {
                _selectedDeliveryIndex = selected ? null : i;
              }),
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pays d'origine
  // ---------------------------------------------------------------------------
  Widget _buildCountrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Pays d'origine"),
        ...List.generate(_countryOptions.length, (i) {
          final country = _countryOptions[i];
          return _CheckboxRow(
            label: country,
            checked: _selectedCountries.contains(country),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedCountries.add(country);
                } else {
                  _selectedCountries.remove(country);
                }
              });
            },
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Certifications
  // ---------------------------------------------------------------------------
  Widget _buildCertSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Certifications'),
        ...List.generate(_certOptions.length, (i) {
          final cert = _certOptions[i];
          return _CheckboxRow(
            label: cert,
            checked: _selectedCerts.contains(cert),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedCerts.add(cert);
                } else {
                  _selectedCerts.remove(cert);
                }
              });
            },
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tri par
  // ---------------------------------------------------------------------------
  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tri par'),
        ...List.generate(_sortOptions.length, (i) {
          return _RadioRow(
            label: _sortOptions[i],
            selected: _selectedSortIndex == i,
            onTap: () => setState(() => _selectedSortIndex = i),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Voir $_resultCount résultats',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.gray6,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange.withOpacity(0.1) : AppColors.gray6,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.orange : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.orange : AppColors.gray1,
          ),
        ),
      ),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: checked,
                onChanged: onChanged,
                activeColor: AppColors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppColors.gray4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: checked ? AppColors.dark : AppColors.gray2,
                fontWeight: checked ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Radio<bool>(
                value: true,
                groupValue: selected ? true : null,
                onChanged: (_) => onTap(),
                activeColor: AppColors.orange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? AppColors.dark : AppColors.gray2,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
