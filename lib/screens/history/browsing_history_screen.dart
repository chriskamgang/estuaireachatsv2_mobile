import 'package:flutter/material.dart';
import '../../core/theme.dart';

class BrowsingHistoryScreen extends StatelessWidget {
  const BrowsingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray6,
      appBar: AppBar(
        title: const Text(
          'Historique',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 72, color: AppColors.gray4),
            const SizedBox(height: 20),
            const Text(
              'Aucun historique',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
            ),
            const SizedBox(height: 10),
            const Text(
              'Votre historique de navigation apparaitra ici',
              style: TextStyle(fontSize: 14, color: AppColors.gray3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
