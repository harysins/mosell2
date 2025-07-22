import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/properties_provider.dart';
import '../constants/app_colors.dart';
import '../screens/home_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertiesProvider>(
      builder: (context, propertiesProvider, child) {
        final favoriteProperties = propertiesProvider.favoriteProperties;

        if (favoriteProperties.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: AppColors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'لا توجد عقارات في المفضلة',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'اضغط على أيقونة القلب لإضافة عقارات للمفضلة',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteProperties.length,
          itemBuilder: (context, index) {
            final property = favoriteProperties[index];
            return PropertyCard(property: property);
          },
        );
      },
    );
  }
}