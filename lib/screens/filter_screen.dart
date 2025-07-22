import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/properties_provider.dart';
import '../models/property_model.dart';
import '../constants/app_colors.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final _cityController = TextEditingController();
  PropertyType? _selectedPropertyType;
  RentSaleType? _selectedRentSaleType;
  double _minPrice = 0;
  double _maxPrice = 1000000000; // 1 billion
  double _minArea = 0;
  double _maxArea = 10000;
  bool? _isCommercial;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final propertiesProvider = Provider.of<PropertiesProvider>(context, listen: false);
    
    propertiesProvider.filterProperties(
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      propertyType: _selectedPropertyType,
      rentSaleType: _selectedRentSaleType,
      minPrice: _minPrice > 0 ? _minPrice : null,
      maxPrice: _maxPrice < 1000000000 ? _maxPrice : null,
      minArea: _minArea > 0 ? _minArea : null,
      maxArea: _maxArea < 10000 ? _maxArea : null,
      isCommercial: _isCommercial,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تطبيق الفلاتر'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _cityController.clear();
      _selectedPropertyType = null;
      _selectedRentSaleType = null;
      _minPrice = 0;
      _maxPrice = 1000000000;
      _minArea = 0;
      _maxArea = 10000;
      _isCommercial = null;
    });

    final propertiesProvider = Provider.of<PropertiesProvider>(context, listen: false);
    propertiesProvider.clearFilters();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم مسح جميع الفلاتر'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فلترة العقارات'),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'مسح الكل',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City Filter
            const Text(
              'المدينة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                hintText: 'ادخل اسم المدينة',
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Property Type Filter
            const Text(
              'نوع العقار',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PropertyType>(
              value: _selectedPropertyType,
              decoration: const InputDecoration(
                hintText: 'اختر نوع العقار',
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
                  _selectedPropertyType = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Rent/Sale Type Filter
            const Text(
              'نوع العرض',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RentSaleType>(
              value: _selectedRentSaleType,
              decoration: const InputDecoration(
                hintText: 'اختر نوع العرض',
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
                  _selectedRentSaleType = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Price Range Filter
            const Text(
              'نطاق السعر (دينار عراقي)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0,
              max: 1000000000,
              divisions: 100,
              labels: RangeLabels(
                _minPrice.toStringAsFixed(0),
                _maxPrice < 1000000000 ? _maxPrice.toStringAsFixed(0) : 'بلا حد',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _minPrice = values.start;
                  _maxPrice = values.end;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('من: ${_minPrice.toStringAsFixed(0)} د.ع'),
                Text(_maxPrice < 1000000000 
                    ? 'إلى: ${_maxPrice.toStringAsFixed(0)} د.ع' 
                    : 'إلى: بلا حد'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Area Range Filter
            const Text(
              'نطاق المساحة (متر مربع)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: RangeValues(_minArea, _maxArea),
              min: 0,
              max: 10000,
              divisions: 100,
              labels: RangeLabels(
                _minArea.toStringAsFixed(0),
                _maxArea < 10000 ? _maxArea.toStringAsFixed(0) : 'بلا حد',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _minArea = values.start;
                  _maxArea = values.end;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('من: ${_minArea.toStringAsFixed(0)} م²'),
                Text(_maxArea < 10000 
                    ? 'إلى: ${_maxArea.toStringAsFixed(0)} م²' 
                    : 'إلى: بلا حد'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Commercial Filter
            const Text(
              'نوع الاستخدام',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<bool>(
              value: _isCommercial,
              decoration: const InputDecoration(
                hintText: 'اختر نوع الاستخدام',
                prefixIcon: Icon(Icons.business),
              ),
              items: const [
                DropdownMenuItem(
                  value: false,
                  child: Text('سكني'),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Text('تجاري'),
                ),
              ],
              onChanged: (bool? value) {
                setState(() {
                  _isCommercial = value;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Apply Filters Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('تطبيق الفلاتر'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}