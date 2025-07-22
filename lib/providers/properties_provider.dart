import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/database_service.dart';

class PropertiesProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<PropertyModel> _properties = [];
  List<PropertyModel> _filteredProperties = [];
  List<PropertyModel> _favoriteProperties = [];
  bool _isLoading = false;

  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get filteredProperties => _filteredProperties;
  List<PropertyModel> get favoriteProperties => _favoriteProperties;
  bool get isLoading => _isLoading;

  // Initialize properties stream
  void initializePropertiesStream() {
    _databaseService.getProperties().listen((properties) {
      _properties = properties;
      _filteredProperties = properties;
      notifyListeners();
    });
  }

  // Add property
  Future<bool> addProperty(PropertyModel property) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _databaseService.addProperty(property);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Filter properties
  void filterProperties({
    String? city,
    PropertyType? propertyType,
    RentSaleType? rentSaleType,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    bool? isCommercial,
  }) {
    _filteredProperties = _properties.where((property) {
      bool matchesCity = city == null || city.isEmpty || property.city.toLowerCase().contains(city.toLowerCase());
      bool matchesType = propertyType == null || property.propertyType == propertyType;
      bool matchesRentSale = rentSaleType == null || property.rentSaleType == rentSaleType;
      bool matchesMinPrice = minPrice == null || property.price >= minPrice;
      bool matchesMaxPrice = maxPrice == null || property.price <= maxPrice;
      bool matchesMinArea = minArea == null || property.area >= minArea;
      bool matchesMaxArea = maxArea == null || property.area <= maxArea;
      bool matchesCommercial = isCommercial == null || property.isCommercial == isCommercial;

      return matchesCity && matchesType && matchesRentSale && matchesMinPrice && 
             matchesMaxPrice && matchesMinArea && matchesMaxArea && matchesCommercial;
    }).toList();

    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _filteredProperties = _properties;
    notifyListeners();
  }

  // Add to favorites
  void addToFavorites(PropertyModel property) {
    if (!_favoriteProperties.any((p) => p.id == property.id)) {
      _favoriteProperties.add(property);
      notifyListeners();
    }
  }

  // Remove from favorites
  void removeFromFavorites(String propertyId) {
    _favoriteProperties.removeWhere((p) => p.id == propertyId);
    notifyListeners();
  }

  // Check if property is favorite
  bool isFavorite(String propertyId) {
    return _favoriteProperties.any((p) => p.id == propertyId);
  }

  // Get broker properties
  Stream<List<PropertyModel>> getBrokerProperties(String brokerId) {
    return _databaseService.getBrokerProperties(brokerId);
  }

  // Add broker rating
  Future<bool> addBrokerRating(String brokerId, double rating) async {
    try {
      await _databaseService.addBrokerRating(brokerId, rating);
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }
}