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
        title: const Text('تطبيق العقارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
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
                if (value == 'profile') {
                  if (user.userType == UserType.broker) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BrokerProfileScreen(brokerId: user.uid),
                      ),
                    );
                  }
                } else if (value == 'logout') {
                  authProvider.signOut();
                }
              },
              itemBuilder: (BuildContext context) => [
                if (user.userType == UserType.broker)
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('الملف الشخصي'),
                  ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('تسجيل الخروج'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: user.photoUrl != null
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U')
                      : null,
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const PropertiesListView(),
          if (user != null && user.userType == UserType.broker) const MyPropertiesView(),
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
}

class PropertiesListView extends StatelessWidget {
  const PropertiesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertiesProvider>(
      builder: (context, propertiesProvider, child) {
        final properties = propertiesProvider.filteredProperties;

        if (properties.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home_work_outlined,
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
}

class PropertyCard extends StatelessWidget {
  final PropertyModel property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final propertiesProvider = Provider.of<PropertiesProvider>(context);
    final isFavorite = propertiesProvider.isFavorite(property.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: AppColors.lightGrey,
              ),
              child: property.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: property.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: AppColors.grey,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.home_work,
                      size: 50,
                      color: AppColors.grey,
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (isFavorite) {
                            propertiesProvider.removeFromFavorites(property.id);
                          } else {
                            propertiesProvider.addToFavorites(property);
                          }
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.error : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text(
                        property.city,
                        style: const TextStyle(color: AppColors.grey),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getPropertyTypeText(property.propertyType),
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: property.rentSaleType == RentSaleType.rent
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          property.rentSaleType == RentSaleType.rent ? 'للإيجار' : 'للبيع',
                          style: TextStyle(
                            color: property.rentSaleType == RentSaleType.rent
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${property.price.toStringAsFixed(0)} د.ع',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Text(
                        '${property.area.toStringAsFixed(0)} م²',
                        style: const TextStyle(
                          color: AppColors.grey,
                        ),
                      ),
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
}

class MyPropertiesView extends StatelessWidget {
  const MyPropertiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: Text('يرجى تسجيل الدخول'));
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