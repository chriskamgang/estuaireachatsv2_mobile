import 'package:flutter/material.dart';

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
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  double get total => _items.where((i) => i.selected).fold(0, (sum, i) => sum + i.price * i.quantity);
  bool get isEmpty => _items.isEmpty;

  void addItem(CartItem item) {
    final existing = _items.indexWhere((i) => i.id == item.id);
    if (existing >= 0) {
      _items[existing].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int qty) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx].quantity = qty;
      notifyListeners();
    }
  }

  void toggleSelection(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx].selected = !_items[idx].selected;
      notifyListeners();
    }
  }

  void toggleAll(bool selected) {
    for (var item in _items) {
      item.selected = selected;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
