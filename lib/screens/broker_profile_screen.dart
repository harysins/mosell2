import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- إضافة هذا للنسخ إلى الحافظة
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
import 'add_property_screen.dart'; // <--- إضافة هذا

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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
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
                allowHalfRating: false,
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
        appBar: AppBar(
          title: const Text('ملف السمسار'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
        ),
        body: const Center(
          child: Text(
            'لم يتم العثور على السمسار',
            style: TextStyle(fontSize: 18, color: AppColors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_broker!.name),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // يمكن إضافة شاشة تعديل الملف الشخصي لاحقاً
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ميزة تعديل الملف الشخصي قريباً'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Broker Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _broker!.photoUrl != null
                        ? CachedNetworkImageProvider(_broker!.photoUrl!)
                        : null,
                    child: _broker!.photoUrl == null
                        ? Text(
                            _broker!.name.isNotEmpty ? _broker!.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 36, color: AppColors.primaryBlue),
                          )
                        : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    _broker!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  if (_broker!.location != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _broker!.location!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.white,
                          ),
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contact Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معلومات الاتصال',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Address
                  if (_broker!.address != null)
                    _buildContactInfo(
                      icon: Icons.home,
                      label: 'العنوان',
                      value: _broker!.address!,
                      onTap: () => _copyToClipboard(_broker!.address!, 'العنوان'),
                    ),
                  
                  // Phone Number
                  if (_broker!.phoneNumber != null)
                    _buildContactInfo(
                      icon: Icons.phone,
                      label: 'رقم الهاتف',
                      value: _broker!.phoneNumber!,
                      onTap: () => _copyToClipboard(_broker!.phoneNumber!, 'رقم الهاتف'),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      if (!isOwnProfile && currentUser != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showRatingDialog,
                            icon: const Icon(Icons.star_rate),
                            label: const Text('تقييم السمسار'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      
                      if (isOwnProfile) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
                              );
                            },
                            icon: const Icon(Icons.add_home),
                            label: const Text('إضافة عقار'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Properties Section
                  const Text(
                    'العقارات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            // Properties List
            StreamBuilder<List<PropertyModel>>(
              stream: Provider.of<PropertiesProvider>(context, listen: false)
                  .getBrokerProperties(widget.brokerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: AppColors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد عقارات',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final properties = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return _buildPropertyCard(property);
                  },
                );
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.copy, color: AppColors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
        child: Row(
          children: [
            // Property Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 100,
                height: 100,
                child: property.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: property.imageUrls[0],
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
                            color: AppColors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.lightGrey,
                        child: const Icon(
                          Icons.home_work,
                          color: AppColors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            
            // Property Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.city,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(property.price),
                      style: const TextStyle(
                        fontSize: 14,
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

  String _formatPrice(double price) {
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
}