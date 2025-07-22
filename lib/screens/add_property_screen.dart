import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/properties_provider.dart';
import '../models/property_model.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _floorsController = TextEditingController();

  PropertyType _selectedPropertyType = PropertyType.house;
  RentSaleType _selectedRentSaleType = RentSaleType.sale;
  bool _isCommercial = false;
  List<File> _selectedImages = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _floorsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.take(5).map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _addProperty() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إضافة صورة واحدة على الأقل'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final propertiesProvider = Provider.of<PropertiesProvider>(context, listen: false);

        // Upload images
        List<String> imageUrls = [];
        for (int i = 0; i < _selectedImages.length; i++) {
          String? imageUrl = await _storageService.uploadFile(
            _selectedImages[i],
            'property_images/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          );
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        }

        // Create property
        PropertyModel property = PropertyModel(
          id: '', // Will be set by Firestore
          brokerId: authProvider.user!.uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrls: imageUrls,
          city: _cityController.text.trim(),
          propertyType: _selectedPropertyType,
          rentSaleType: _selectedRentSaleType,
          price: double.parse(_priceController.text.trim()),
          area: double.parse(_areaController.text.trim()),
          floors: _floorsController.text.trim().isNotEmpty 
              ? int.parse(_floorsController.text.trim()) 
              : null,
          isCommercial: _isCommercial,
          createdAt: Timestamp.now(),
        );

        bool success = await propertiesProvider.addProperty(property);

        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة العقار بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في إضافة العقار'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة عقار جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Section
              const Text(
                'صور العقار (حد أقصى 5 صور)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.lightGrey,
                  ),
                  child: _selectedImages.isEmpty
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: AppColors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'اضغط لإضافة صور',
                              style: TextStyle(color: AppColors.grey),
                            ),
                          ],
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.all(8),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان العقار',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال عنوان العقار';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف العقار',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال وصف العقار';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'المدينة',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال المدينة';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Property Type
              DropdownButtonFormField<PropertyType>(
                value: _selectedPropertyType,
                decoration: const InputDecoration(
                  labelText: 'نوع العقار',
                  prefixIcon: Icon(Icons.home),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PropertyType.house,
                    child: Text('بيت'),
                  ),
                  DropdownMenuItem(
                    value: PropertyType.apartment,
                    child: Text('شقة'),
                  ),
                  DropdownMenuItem(
                    value: PropertyType.land,
                    child: Text('أرض'),
                  ),
                  DropdownMenuItem(
                    value: PropertyType.commercial,
                    child: Text('تجاري'),
                  ),
                ],
                onChanged: (PropertyType? value) {
                  setState(() {
                    _selectedPropertyType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Rent/Sale Type
              DropdownButtonFormField<RentSaleType>(
                value: _selectedRentSaleType,
                decoration: const InputDecoration(
                  labelText: 'نوع العرض',
                  prefixIcon: Icon(Icons.sell),
                ),
                items: const [
                  DropdownMenuItem(
                    value: RentSaleType.sale,
                    child: Text('للبيع'),
                  ),
                  DropdownMenuItem(
                    value: RentSaleType.rent,
                    child: Text('للإيجار'),
                  ),
                ],
                onChanged: (RentSaleType? value) {
                  setState(() {
                    _selectedRentSaleType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر (دينار عراقي)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال السعر';
                  }
                  if (double.tryParse(value) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Area
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'المساحة (متر مربع)',
                  prefixIcon: Icon(Icons.square_foot),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال المساحة';
                  }
                  if (double.tryParse(value) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Floors (optional)
              if (_selectedPropertyType == PropertyType.house || 
                  _selectedPropertyType == PropertyType.apartment)
                TextFormField(
                  controller: _floorsController,
                  decoration: const InputDecoration(
                    labelText: 'عدد الطوابق (اختياري)',
                    prefixIcon: Icon(Icons.layers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                    }
                    return null;
                  },
                ),
              
              const SizedBox(height: 16),
              
              // Commercial checkbox
              CheckboxListTile(
                title: const Text('عقار تجاري'),
                value: _isCommercial,
                onChanged: (bool? value) {
                  setState(() {
                    _isCommercial = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addProperty,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : const Text('إضافة العقار'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}