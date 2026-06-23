import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../data/mock_data.dart';
import '../screens/product/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final MockProduct product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray5, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(product.image, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.gray5, child: const Center(child: Icon(Icons.image, color: AppColors.gray4)))),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.image_search, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.dark, height: 1.3),
                    ),
                    const Spacer(),
                    Text(
                      formatPriceRange(product.priceMin, product.priceMax),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark),
                    ),
                    const SizedBox(height: 2),
                    Text('MOQ: ${product.moq}', style: TextStyle(fontSize: 10, color: AppColors.gray3)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (product.verified) ...[
                          Text('Vérifié', style: TextStyle(fontSize: 9, color: Colors.orange.shade800, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                        ],
                        Flexible(child: Text('${product.sellerYears} ans · ${product.origin}', style: TextStyle(fontSize: 9, color: AppColors.gray3), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
