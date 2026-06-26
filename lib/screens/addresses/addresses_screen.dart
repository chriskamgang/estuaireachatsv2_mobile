import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/api_service.dart';
import '../../core/theme.dart';
import 'edit_address_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ApiService().get('/addresses');
      final List data = res.data['data'] ?? [];
      setState(() {
        _addresses = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les adresses';
      });
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.red),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(fontSize: 14, color: AppColors.gray2)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadAddresses,
                        child: const Text('Reessayer', style: TextStyle(color: AppColors.orange)),
                      ),
                    ],
                  ),
                )
              : _addresses.isEmpty
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

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final name = address['fullName'] ?? '';
    final phone = address['phone'] ?? '';
    final addr = address['address'] ?? '';
    final city = address['city'] ?? '';
    final country = address['country'] ?? 'Cameroun';
    final isDefault = address['isDefault'] == true;
    final id = address['id']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDefault ? AppColors.orange.withOpacity(0.4) : AppColors.gray5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              if (isDefault)
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
          Text(phone, style: const TextStyle(fontSize: 13, color: AppColors.gray2)),
          const SizedBox(height: 4),
          Text(addr, style: const TextStyle(fontSize: 13, color: AppColors.gray2)),
          Text('$city, $country', style: const TextStyle(fontSize: 13, color: AppColors.gray2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () async {
                  final addressData = AddressData(
                    id: id,
                    name: name,
                    phone: phone,
                    address: addr,
                    city: city,
                    country: country,
                    isDefault: isDefault,
                  );
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditAddressScreen(
                        address: addressData,
                        onSave: (updated) async {
                          try {
                            await ApiService().patch('/addresses/$id', data: {
                              'fullName': updated.name,
                              'phone': updated.phone,
                              'address': updated.address,
                              'city': updated.city,
                              'country': updated.country,
                              'isDefault': updated.isDefault,
                            });
                          } catch (_) {}
                        },
                      ),
                    ),
                  );
                  _loadAddresses();
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
                        'Voulez-vous supprimer l\'adresse de $name ?',
                        style: const TextStyle(fontSize: 14, color: AppColors.gray2),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler', style: TextStyle(color: AppColors.gray2)),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            try {
                              await ApiService().delete('/addresses/$id');
                              _loadAddresses();
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Erreur lors de la suppression')),
                                );
                              }
                            }
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
    LatLng markerPosition = const LatLng(4.0511, 9.7679);

    final cities = ['Douala', 'Yaounde', 'Bafoussam', 'Bamenda', 'Garoua', 'Kribi', 'Limbe'];

    Future<void> reverseGeocode(LatLng position, void Function(void Function()) setSheetState) async {
      const apiKey = 'AIzaSyAffUHSFli6kMnjkfJOKBGO6AN828ixJPo';
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['results'] != null && (data['results'] as List).isNotEmpty) {
            final result = data['results'][0];
            final formattedAddress = result['formatted_address'] as String? ?? '';
            setSheetState(() {
              addressController.text = formattedAddress;
            });
            // Try to extract city from address components
            final components = result['address_components'] as List? ?? [];
            for (final comp in components) {
              final types = (comp['types'] as List?) ?? [];
              if (types.contains('locality')) {
                final cityName = comp['long_name'] as String? ?? '';
                if (cities.contains(cityName)) {
                  setSheetState(() {
                    selectedCity = cityName;
                  });
                }
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

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
                    const Text('Choisir sur la carte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: markerPosition,
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: markerPosition,
                              draggable: true,
                              onDragEnd: (newPosition) {
                                setSheetState(() {
                                  markerPosition = newPosition;
                                });
                                reverseGeocode(newPosition, setSheetState);
                              },
                            ),
                          },
                          onTap: (position) {
                            setSheetState(() {
                              markerPosition = position;
                            });
                            reverseGeocode(position, setSheetState);
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ),
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
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
                            return;
                          }
                          try {
                            await ApiService().post('/addresses', data: {
                              'fullName': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'address': addressController.text.trim(),
                              'city': selectedCity,
                              'country': 'Cameroun',
                              'isDefault': isDefault,
                              'latitude': markerPosition.latitude,
                              'longitude': markerPosition.longitude,
                            });
                            Navigator.pop(ctx);
                            _loadAddresses();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erreur lors de l\'enregistrement')),
                              );
                            }
                          }
                        },
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
