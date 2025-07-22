import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyType {
  apartment,
  house,
  land,
  commercial,
}

enum RentSaleType {
  rent,
  sale,
}

class PropertyModel {
  final String id;
  final String brokerId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String city;
  final PropertyType propertyType;
  final RentSaleType rentSaleType;
  final double price;
  final double area;
  final int? floors;
  final bool isCommercial;
  final Timestamp createdAt;

  PropertyModel({
    required this.id,
    required this.brokerId,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.city,
    required this.propertyType,
    required this.rentSaleType,
    required this.price,
    required this.area,
    this.floors,
    required this.isCommercial,
    required this.createdAt,
  });

  // Factory constructor to create a PropertyModel from a Firestore document
  factory PropertyModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyModel(
      id: doc.id,
      brokerId: data['brokerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      city: data['city'] ?? '',
      propertyType: _stringToPropertyType(data['propertyType']),
      rentSaleType: _stringToRentSaleType(data['rentSaleType']),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      area: (data['area'] as num?)?.toDouble() ?? 0.0,
      floors: data['floors'],
      isCommercial: data['isCommercial'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Method to convert a PropertyModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'brokerId': brokerId,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'city': city,
      'propertyType': propertyType.toString().split('.').last,
      'rentSaleType': rentSaleType.toString().split('.').last,
      'price': price,
      'area': area,
      'floors': floors,
      'isCommercial': isCommercial,
      'createdAt': createdAt,
    };
  }

  static PropertyType _stringToPropertyType(String type) {
    switch (type) {
      case 'apartment':
        return PropertyType.apartment;
      case 'house':
        return PropertyType.house;
      case 'land':
        return PropertyType.land;
      case 'commercial':
        return PropertyType.commercial;
      default:
        return PropertyType.house; // Default value
    }
  }

  static RentSaleType _stringToRentSaleType(String type) {
    switch (type) {
      case 'rent':
        return RentSaleType.rent;
      case 'sale':
        return RentSaleType.sale;
      default:
        return RentSaleType.sale; // Default value
    }
  }
}