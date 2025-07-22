import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/properties_provider.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'broker_profile_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final AuthService _authService = AuthService();
  UserModel? _broker;
  bool _isLoadingBroker = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBrokerData();
  }

  Future<void> _loadBrokerData() async {
    try {
      UserModel? broker = await _authService.getUserData(
        widget.property.brokerId,
      );
      setState(() {
        _broker = broker;
        _isLoadingBroker = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBroker = false;
      });
    }
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final propertiesProvider = Provider.of<PropertiesProvider>(context);
    final isFavorite = propertiesProvider.isFavorite(widget.property.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Images
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.property.imageUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: widget.property.imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: widget.property.imageUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.lightGrey,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: AppColors.grey,
                            ),
                          ),
                        );
                      },
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
            actions: [
              IconButton(
                onPressed: () {
                  if (isFavorite) {
                    propertiesProvider.removeFromFavorites(widget.property.id);
                  } else {
                    propertiesProvider.addToFavorites(widget.property);
                  }
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.error : AppColors.white,
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Indicators
                  if (widget.property.imageUrls.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.property.imageUrls.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? AppColors.primaryBlue
                                : AppColors.grey,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.property.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${widget.property.price.toStringAsFixed(0)} د.ع',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.property.rentSaleType ==
                                      RentSaleType.rent
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.property.rentSaleType == RentSaleType.rent
                                  ? 'للإيجار'
                                  : 'للبيع',
                              style: TextStyle(
                                color:
                                    widget.property.rentSaleType ==
                                        RentSaleType.rent
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.property.city,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Property Details
                  const Text(
                    'تفاصيل العقار',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'نوع العقار',
                          _getPropertyTypeText(widget.property.propertyType),
                        ),
                        _buildDetailRow(
                          'المساحة',
                          '${widget.property.area.toStringAsFixed(0)} م²',
                        ),
                        if (widget.property.floors != null)
                          _buildDetailRow(
                            'عدد الطوابق',
                            widget.property.floors.toString(),
                          ),
                        _buildDetailRow(
                          'نوع الاستخدام',
                          widget.property.isCommercial ? 'تجاري' : 'سكني',
                        ),
                        _buildDetailRow(
                          'تاريخ النشر',
                          _formatDate(widget.property.createdAt.toDate()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'الوصف',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    widget.property.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // Broker Information
                  const Text(
                    'معلومات السمسار',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingBroker)
                    const Center(child: CircularProgressIndicator())
                  else if (_broker != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BrokerProfileScreen(brokerId: _broker!.uid),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: _broker!.photoUrl != null
                                  ? CachedNetworkImageProvider(
                                      _broker!.photoUrl!,
                                    )
                                  : null,
                              child: _broker!.photoUrl == null
                                  ? Text(
                                      _broker!.name.isNotEmpty
                                          ? _broker!.name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(fontSize: 20),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _broker!.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_broker!.location != null)
                                    Text(
                                      _broker!.location!,
                                      style: const TextStyle(
                                        color: AppColors.grey,
                                      ),
                                    ),
                                  if (_broker!.rating != null &&
                                      _broker!.ratingCount != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_broker!.rating!.toStringAsFixed(1)} (${_broker!.ratingCount} تقييم)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.grey,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Text(
                      'لم يتم العثور على معلومات السمسار',
                      style: TextStyle(color: AppColors.grey),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: AppColors.grey)),
        ],
      ),
    );
  }
}
