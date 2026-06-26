import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';

class CartItem {
  final String id;
  final String name;
  final String image;
  final double price;
  final String seller;
  int quantity;
  bool selected;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.seller,
    this.quantity = 1,
    this.selected = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'price': price,
    'seller': seller,
    'quantity': quantity,
    'selected': selected,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    name: json['name'] as String,
    image: json['image'] as String,
    price: (json['price'] as num).toDouble(),
    seller: json['seller'] as String,
    quantity: json['quantity'] as int? ?? 1,
    selected: json['selected'] as bool? ?? true,
  );
}

class CartProvider extends ChangeNotifier {
  static const _storageKey = 'cart_items';
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  double get total => _items.where((i) => i.selected).fold(0, (sum, i) => sum + i.price * i.quantity);
  bool get isEmpty => _items.isEmpty;

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _items.clear();
        _items.addAll(decoded.map((e) => CartItem.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      } catch (_) {
        // Corrupted data, ignore
      }
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  void addItem(CartItem item) {
    final existing = _items.indexWhere((i) => i.id == item.id);
    if (existing >= 0) {
      _items[existing].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
    _saveCart();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    _saveCart();
  }

  void updateQuantity(String id, int qty) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx].quantity = qty;
      notifyListeners();
      _saveCart();
    }
  }

  void toggleSelection(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx].selected = !_items[idx].selected;
      notifyListeners();
      _saveCart();
    }
  }

  void toggleAll(bool selected) {
    for (var item in _items) {
      item.selected = selected;
    }
    notifyListeners();
    _saveCart();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }

  /// Sync selected local cart items to the backend cart (DB).
  /// Must be called before creating an order, since POST /orders reads from DB cart.
  Future<void> syncToBackend() async {
    final api = ApiService();
    // Clear backend cart first to avoid duplicates
    try {
      await api.delete('/cart/clear');
    } catch (_) {
      // Endpoint may not exist, continue
    }
    // Add each selected item to backend cart
    for (final item in _items.where((i) => i.selected)) {
      try {
        await api.post('/cart/add', data: {
          'productId': item.id,
          'quantity': item.quantity,
        });
      } catch (_) {
        // Continue with next item
      }
    }
  }
}
