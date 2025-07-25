import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/properties_provider.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../constants/app_colors.dart';
import 'property_details_screen.dart';
import 'add_property_screen.dart';
import 'broker_profile_screen.dart';
import 'favorites_screen.dart';
import 'filter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            // App Logo - يمكنك استبدال هذا بصورة mosell_1 الخاصة بك
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.home_work,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              // إذا كان لديك صورة mosell_1، استخدم هذا بدلاً من الأيقونة:
              // child: Image.asset(
              //   'assets/images/mosell_1.png', // تأكد من إضافة الصورة في مجلد assets
              //   fit: BoxFit.contain,
              // ),
            ),
            const SizedBox(width: 12),
            const Text(
              'mosell',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Search/Filter Icon
          IconButton(
            icon: const Icon(Icons.search), // تم تغيير الأيقونة من filter_list إلى search
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FilterScreen()),
              );
            },
          ),
          if (user != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile' && user.userType == UserType.broker) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BrokerProfileScreen(brokerId: user.uid),
                    ),
                  );
                } else if (value == 'logout') {
                  authProvider.signOut();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  if (user.userType == UserType.broker)
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Text('الملف الشخصي'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('تسجيل الخروج'),
                  ),
                ];
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildPropertiesView(),
          if (user != null && user.userType == UserType.broker) _buildMyPropertiesView(),
          const FavoritesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          if (user != null && user.userType == UserType.broker)
            const BottomNavigationBarItem(
              icon: Icon(Icons.business),
              label: 'عقاراتي',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'المفضلة',
          ),
        ],
      ),
      floatingActionButton: user != null && user.userType == UserType.broker
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
                );
              },
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
    );
  }

  Widget _buildPropertiesView() {
    return Consumer<PropertiesProvider>(
      builder: (context, propertiesProvider, child) {
        final properties = propertiesProvider.filteredProperties;

        if (properties.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 64,
                  color: AppColors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'لا توجد عقارات متاحة',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            return PropertyCard(property: property);
          },
        );
      },
    );
  }

  Widget _buildMyPropertiesView() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(
        child: Text(
          'يرجى تسجيل الدخول',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.grey,
          ),
        ),
      );
    }

    return StreamBuilder<List<PropertyModel>>(
      stream: Provider.of<PropertiesProvider>(context, listen: false)
          .getBrokerProperties(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 64,
                  color: AppColors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'لم تقم بإضافة أي عقارات بعد',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final properties = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            return PropertyCard(property: property);
          },
        );
      },
    );
  }
}

class PropertyCard extends StatelessWidget {
  final PropertyModel property;

  const PropertyCard({super.key, required this.property});

  String _getPropertyTypeText(PropertyType type) {
    switch (type) {
      case PropertyType.apartment:
        return 'شقة';
      case PropertyType.house:
        return 'بيت';
      case PropertyType.land:
        return 'أرض';
      case PropertyType.commercial:
        return 'تجاري';
    }
  }

  String _formatPrice(double price) {
    // تنسيق السعر بالملايين لتجنب الأصفار الكثيرة
    if (price >= 1000000) {
      double millions = price / 1000000;
      if (millions == millions.toInt()) {
        return '${millions.toInt()} مليون د.ع';
      } else {
        return '${millions.toStringAsFixed(1)} مليون د.ع';
      }
    } else if (price >= 1000) {
      double thousands = price / 1000;
      if (thousands == thousands.toInt()) {
        return '${thousands.toInt()} ألف د.ع';
      } else {
        return '${thousands.toStringAsFixed(1)} ألف د.ع';
      }
    } else {
      return '${price.toStringAsFixed(0)} د.ع';
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesProvider = Provider.of<PropertiesProvider>(context);
    final isFavorite = propertiesProvider.isFavorite(property.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(property: property),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: property.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: property.imageUrls[0],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.lightGrey,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.lightGrey,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: AppColors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.lightGrey,
                            child: const Icon(
                              Icons.home_work,
                              size: 80,
                              color: AppColors.grey,
                            ),
                          ),
                  ),
                  
                  // Favorite Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        if (isFavorite) {
                          propertiesProvider.removeFromFavorites(property.id);
                        } else {
                          propertiesProvider.addToFavorites(property);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.error : AppColors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  
                  // Property Type Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: property.rentSaleType == RentSaleType.rent
                            ? AppColors.success
                            : AppColors.warning,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        property.rentSaleType == RentSaleType.rent ? 'للإيجار' : 'للبيع',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Property Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatPrice(property.price), // استخدام الدالة الجديدة لتنسيق السعر
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        property.city,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Property Info
                  Row(
                    children: [
                      _buildInfoChip(_getPropertyTypeText(property.propertyType)),
                      const SizedBox(width: 8),
                      _buildInfoChip('${property.area.toStringAsFixed(0)} م²'),
                      if (property.floors != null) ...[
                        const SizedBox(width: 8),
                        _buildInfoChip('${property.floors} طوابق'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.grey,
        ),
      ),
    );
  }
}