import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../providers/auth_provider.dart';
import '../providers/properties_provider.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'property_details_screen.dart';

class BrokerProfileScreen extends StatefulWidget {
  final String brokerId;

  const BrokerProfileScreen({super.key, required this.brokerId});

  @override
  State<BrokerProfileScreen> createState() => _BrokerProfileScreenState();
}

class _BrokerProfileScreenState extends State<BrokerProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _broker;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBrokerData();
  }

  Future<void> _loadBrokerData() async {
    try {
      UserModel? broker = await _authService.getUserData(widget.brokerId);
      setState(() {
        _broker = broker;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRatingDialog() {
    double rating = 0;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تقييم السمسار'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('كيف تقيم خدمة هذا السمسار؟'),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (newRating) {
                  rating = newRating;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (rating > 0) {
                  final propertiesProvider = Provider.of<PropertiesProvider>(context, listen: false);
                  bool success = await propertiesProvider.addBrokerRating(widget.brokerId, rating);
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إضافة التقييم بنجاح'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _loadBrokerData(); // Reload broker data to show updated rating
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('فشل في إضافة التقييم'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('تقييم'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    final isOwnProfile = currentUser?.uid == widget.brokerId;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_broker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: const Center(
          child: Text('لم يتم العثور على السمسار'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'ملفي الشخصي' : 'ملف السمسار'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _broker!.photoUrl != null
                        ? CachedNetworkImageProvider(_broker!.photoUrl!)
                        : null,
                    child: _broker!.photoUrl == null
                        ? Text(
                            _broker!.name.isNotEmpty ? _broker!.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 32, color: AppColors.white),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _broker!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_broker!.location != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _broker!.location!,
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Rating
                  if (_broker!.rating != null && _broker!.ratingCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${_broker!.rating!.toStringAsFixed(1)} (${_broker!.ratingCount} تقييم)',
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  
                  if (!isOwnProfile && currentUser != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: _showRatingDialog,
                        icon: const Icon(Icons.star_rate),
                        label: const Text('تقييم السمسار'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Properties Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwnProfile ? 'عقاراتي' : 'عقارات السمسار',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  StreamBuilder<List<PropertyModel>>(
                    stream: Provider.of<PropertiesProvider>(context, listen: false)
                        .getBrokerProperties(widget.brokerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.business_outlined,
                                size: 64,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isOwnProfile 
                                    ? 'لم تقم بإضافة أي عقارات بعد'
                                    : 'لا توجد عقارات لهذا السمسار',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final properties = snapshot.data!;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: properties.length,
                        itemBuilder: (context, index) {
                          final property = properties[index];
                          return PropertyGridCard(property: property);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyGridCard extends StatelessWidget {
  final PropertyModel property;

  const PropertyGridCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
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
            Expanded(
              flex: 3,
              child: Container(
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
                            size: 30,
                            color: AppColors.grey,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.home_work,
                        size: 30,
                        color: AppColors.grey,
                      ),
              ),
            ),
            
            // Property Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.city,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${property.price.toStringAsFixed(0)} د.ع',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
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