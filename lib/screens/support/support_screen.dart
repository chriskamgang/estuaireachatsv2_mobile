import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();

  // Formulaire de contact
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'commande';
  bool _sending = false;

  static const _categories = [
    {'value': 'commande', 'label': 'Probleme de commande'},
    {'value': 'paiement', 'label': 'Probleme de paiement'},
    {'value': 'livraison', 'label': 'Probleme de livraison'},
    {'value': 'produit', 'label': 'Probleme produit'},
    {'value': 'compte', 'label': 'Probleme de compte'},
    {'value': 'autre', 'label': 'Autre'},
  ];

  static const _faqs = [
    {
      'question': 'Comment suivre ma commande ?',
      'answer': 'Rendez-vous dans "Mes commandes" depuis votre profil. Cliquez sur la commande concernee pour voir son statut de livraison en temps reel.',
    },
    {
      'question': 'Comment retourner un produit ?',
      'answer': 'Vous disposez de 15 jours apres reception pour demander un retour. Allez dans "Mes commandes", selectionnez la commande et cliquez sur "Demander un retour".',
    },
    {
      'question': 'Quels sont les modes de paiement acceptes ?',
      'answer': 'Nous acceptons MTN Mobile Money, Orange Money, les cartes bancaires (Visa, Mastercard) et PayPal.',
    },
    {
      'question': 'Comment modifier mon adresse de livraison ?',
      'answer': 'Vous pouvez modifier vos adresses de livraison depuis "Mon profil > Adresse d\'expedition". Vous pouvez ajouter jusqu\'a 5 adresses.',
    },
    {
      'question': 'Les produits sont-ils garantis authentiques ?',
      'answer': 'EstuaireAchats verifie tous ses vendeurs. Les produits "Certifie EA" ont subi un controle qualite supplementaire. En cas de produit non conforme, nous remboursons integralement.',
    },
    {
      'question': 'Comment contacter un vendeur ?',
      'answer': 'Sur la page produit, cliquez sur le nom du vendeur puis sur "Contacter". Vous pouvez aussi envoyer un message depuis votre historique de commandes.',
    },
    {
      'question': 'Quels sont les delais de livraison ?',
      'answer': 'Les delais varient selon le vendeur et votre localisation : 3-7 jours pour Douala/Yaounde, 7-14 jours pour les autres villes du Cameroun.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await _api.post('/support/tickets', data: {
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'category': _selectedCategory,
      });
      if (mounted) {
        _subjectController.clear();
        _messageController.clear();
        setState(() => _selectedCategory = 'commande');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre demande a ete envoyee. Nous vous repondrons sous 24h.'),
            backgroundColor: AppColors.green,
            duration: Duration(seconds: 4),
          ),
        );
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi. Veuillez reessayer.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text(
          'Aide & Support',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray3,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Nous contacter'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaq(),
          _buildContactForm(),
        ],
      ),
    );
  }

  Widget _buildFaq() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _faqs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.gray3,
            title: Text(
              faq['question']!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
            ),
            children: [
              Text(
                faq['answer']!,
                style: const TextStyle(fontSize: 13, color: AppColors.gray2, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Nous repondons generalement sous 24h en jours ouvrables.',
                      style: TextStyle(fontSize: 12, color: AppColors.gray1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Categorie
            const Text('Categorie', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14, color: AppColors.dark),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sujet
            const Text('Sujet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Decrivez brievement votre probleme',
                hintStyle: const TextStyle(color: AppColors.gray3, fontSize: 14),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.gray5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez saisir un sujet' : null,
            ),
            const SizedBox(height: 16),

            // Message
            const Text('Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Decrivez votre probleme en detail...',
                hintStyle: const TextStyle(color: AppColors.gray3, fontSize: 14),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.gray5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (v) => v == null || v.trim().length < 10 ? 'Veuillez saisir un message (min. 10 caracteres)' : null,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Envoyer ma demande', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
