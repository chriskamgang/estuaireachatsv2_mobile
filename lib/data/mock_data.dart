class MockProduct {
  final String id;
  final String name;
  final String image;
  final double priceMin;
  final double priceMax;
  final int moq;
  final String seller;
  final String origin;
  final int sellerYears;
  final bool verified;
  final int sold;
  final double rating;
  final int reviews;
  final String? deliveryEstimate;
  final String category;

  const MockProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.priceMin,
    required this.priceMax,
    required this.moq,
    required this.seller,
    required this.origin,
    required this.sellerYears,
    this.verified = false,
    this.sold = 0,
    this.rating = 0,
    this.reviews = 0,
    this.deliveryEstimate,
    this.category = '',
  });
}

class MockCategory {
  final String id;
  final String name;
  final String icon;
  final List<MockSubCategory> subCategories;

  const MockCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.subCategories = const [],
  });
}

class MockSubCategory {
  final String id;
  final String name;

  const MockSubCategory({required this.id, required this.name});
}

class MockData {
  static const List<MockProduct> products = [
    MockProduct(id: '1', name: 'Samsung Galaxy A54 256GB Smartphone Android', image: 'https://picsum.photos/seed/p1/400/400', priceMin: 120000, priceMax: 150000, moq: 1, seller: 'TechStore Douala', origin: 'CN', sellerYears: 5, verified: true, sold: 342, rating: 4.5, reviews: 120, deliveryEstimate: 'Livraison avant le 15 juil.', category: 'Electronique'),
    MockProduct(id: '2', name: 'Ecouteurs Bluetooth TWS Casque Sans Fil', image: 'https://picsum.photos/seed/p2/400/400', priceMin: 5000, priceMax: 15000, moq: 10, seller: 'AudioPro CM', origin: 'CN', sellerYears: 3, verified: true, sold: 1093, rating: 4.2, reviews: 350, category: 'Electronique'),
    MockProduct(id: '3', name: 'Chaussures Sport Homme Running Respirantes', image: 'https://picsum.photos/seed/p3/400/400', priceMin: 8000, priceMax: 25000, moq: 2, seller: 'FashionCM', origin: 'CN', sellerYears: 7, verified: true, sold: 567, rating: 4.3, reviews: 89, deliveryEstimate: 'Livraison avant le 19 aout', category: 'Chaussures'),
    MockProduct(id: '4', name: 'Camera de Recul Voiture HD Vision Nocturne', image: 'https://picsum.photos/seed/p4/400/400', priceMin: 15000, priceMax: 45000, moq: 1, seller: 'AutoParts Yaounde', origin: 'CN', sellerYears: 2, verified: false, sold: 45, rating: 4.0, reviews: 12, category: 'Fournitures auto'),
    MockProduct(id: '5', name: 'Robe Africaine Wax Femme Pagne Traditionnelle', image: 'https://picsum.photos/seed/p5/400/400', priceMin: 12000, priceMax: 35000, moq: 5, seller: 'AfrikaMode', origin: 'CM', sellerYears: 4, verified: true, sold: 234, rating: 4.7, reviews: 67, category: 'Vetements'),
    MockProduct(id: '6', name: 'Ventilateur Plafond LED Telecommande Silencieux', image: 'https://picsum.photos/seed/p6/400/400', priceMin: 35000, priceMax: 75000, moq: 1, seller: 'HomePlus', origin: 'CN', sellerYears: 8, verified: true, sold: 89, rating: 4.4, reviews: 34, deliveryEstimate: 'Livraison avant le 25 juil.', category: 'Maison'),
    MockProduct(id: '7', name: 'Huile de Coco Bio Vierge Extra 500ml', image: 'https://picsum.photos/seed/p7/400/400', priceMin: 3000, priceMax: 8000, moq: 20, seller: 'NaturelBio CM', origin: 'CM', sellerYears: 2, verified: false, sold: 456, rating: 4.6, reviews: 123, category: 'Beaute'),
    MockProduct(id: '8', name: 'Alarme Voiture Universelle Telecommande Antivol', image: 'https://picsum.photos/seed/p8/400/400', priceMin: 9000, priceMax: 25000, moq: 1, seller: 'SecuAuto', origin: 'CN', sellerYears: 12, verified: true, sold: 178, rating: 4.1, reviews: 56, category: 'Fournitures auto'),
    MockProduct(id: '9', name: 'Imprimante Multifonction Laser Couleur A4', image: 'https://picsum.photos/seed/p9/400/400', priceMin: 95000, priceMax: 250000, moq: 1, seller: 'BureauTech', origin: 'CN', sellerYears: 6, verified: true, sold: 67, rating: 4.3, reviews: 23, category: 'Electronique'),
    MockProduct(id: '10', name: 'Kit Panneau Solaire 100W + Batterie + Onduleur', image: 'https://picsum.photos/seed/p10/400/400', priceMin: 150000, priceMax: 450000, moq: 1, seller: 'SolarCM', origin: 'CN', sellerYears: 5, verified: true, sold: 34, rating: 4.8, reviews: 15, category: 'Maison'),
    MockProduct(id: '11', name: 'Montre Connectee Smartwatch Sport Etanche', image: 'https://picsum.photos/seed/p11/400/400', priceMin: 15000, priceMax: 45000, moq: 2, seller: 'WatchPro', origin: 'CN', sellerYears: 4, verified: true, sold: 312, rating: 4.2, reviews: 89, category: 'Electronique'),
    MockProduct(id: '12', name: 'Sac a Dos Ordinateur 15.6 pouces Etanche', image: 'https://picsum.photos/seed/p12/400/400', priceMin: 8000, priceMax: 20000, moq: 5, seller: 'BagStore', origin: 'CN', sellerYears: 3, verified: false, sold: 245, rating: 4.4, reviews: 78, category: 'Bagages'),
  ];

  static const List<MockCategory> categories = [
    MockCategory(id: '1', name: 'Pour vous', icon: '✨', subCategories: [
      MockSubCategory(id: '1a', name: 'Produit a succes'),
      MockSubCategory(id: '1b', name: 'Lecteur DVD'),
      MockSubCategory(id: '1c', name: 'Boite noire voiture'),
      MockSubCategory(id: '1d', name: 'Kit voiture Bluetooth'),
      MockSubCategory(id: '1e', name: 'Telecommandes'),
      MockSubCategory(id: '1f', name: 'Cles de vehicule'),
    ]),
    MockCategory(id: '2', name: 'En vedette', icon: '⭐', subCategories: [
      MockSubCategory(id: '2a', name: 'Batiment jardin'),
      MockSubCategory(id: '2b', name: 'Systeme karaoke'),
      MockSubCategory(id: '2c', name: 'Stores-bannes'),
      MockSubCategory(id: '2d', name: 'Serres de jardin'),
    ]),
    MockCategory(id: '3', name: 'Offres speciales', icon: '🔥', subCategories: [
      MockSubCategory(id: '3a', name: 'Demarreur'),
      MockSubCategory(id: '3b', name: 'Outils diagnostic'),
      MockSubCategory(id: '3c', name: 'Serrures intelligentes'),
      MockSubCategory(id: '3d', name: 'Changeurs pneus'),
      MockSubCategory(id: '3e', name: 'Camera reseau'),
    ]),
    MockCategory(id: '4', name: 'Vetements & Accessoires', icon: '👕'),
    MockCategory(id: '5', name: 'Electronique', icon: '📱', subCategories: [
      MockSubCategory(id: '5a', name: 'Smartphones'),
      MockSubCategory(id: '5b', name: 'Tablettes'),
      MockSubCategory(id: '5c', name: 'Ordinateurs portables'),
      MockSubCategory(id: '5d', name: 'Accessoires PC'),
      MockSubCategory(id: '5e', name: 'Audio & Video'),
    ]),
    MockCategory(id: '6', name: 'Maison & Jardin', icon: '🏠'),
    MockCategory(id: '7', name: 'Sports & Loisirs', icon: '⚽'),
    MockCategory(id: '8', name: 'Fournitures auto', icon: '🚗', subCategories: [
      MockSubCategory(id: '8a', name: 'Eclairage'),
      MockSubCategory(id: '8b', name: 'Alarmes'),
      MockSubCategory(id: '8c', name: 'Accessoires interieur'),
      MockSubCategory(id: '8d', name: 'Pieces moteur'),
    ]),
    MockCategory(id: '9', name: 'Produits de beaute', icon: '💄'),
    MockCategory(id: '10', name: 'Bijoux & Montres', icon: '💎'),
    MockCategory(id: '11', name: 'Chaussures & Accessoires', icon: '👟'),
    MockCategory(id: '12', name: 'Bagages & Sacs', icon: '🎒'),
    MockCategory(id: '13', name: 'Emballage & Impression', icon: '📦'),
  ];

  static const List<Map<String, String>> conversations = [
    {'name': 'Klaus Zeng', 'company': 'Foshan Chuanglibao Packaging', 'message': 'Besoin d\'une traduction ? Essayez notre fonction...', 'date': '2026/03/12', 'unread': '2'},
    {'name': 'Ieon Lee', 'company': 'Henan Blick Refractory Technology', 'message': 'Have questions about our products? Join our Q&A...', 'date': '2025/09/12', 'unread': '99+'},
    {'name': 'Clelo China Logistics', 'company': 'American Pacific Rim Luxury Goods', 'message': 'Besoin d\'une traduction ? Essayez notre fonction...', 'date': '2025/08/08', 'unread': '1'},
    {'name': 'Judy Xue', 'company': 'Xinxiang Dongzhen Machinery', 'message': '[Fichier] Product Catalog--Dongzhen Machinery.pdf', 'date': '2025/05/29', 'unread': '2'},
    {'name': 'Mei He', 'company': 'Xinxiang Gaofu Machinery', 'message': 'Hello, how can we help you today?', 'date': '2024/08/31', 'unread': '0'},
  ];
}
