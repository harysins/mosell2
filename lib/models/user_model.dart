import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType {
  broker,
  buyer,
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final UserType userType;
  final String? location;
  final String? address; // <--- حقل جديد للعنوان
  final String? phoneNumber; // <--- حقل جديد لرقم الهاتف
  final double? rating;
  final int? ratingCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.userType,
    this.location,
    this.address, // <--- إضافة الحقل الجديد
    this.phoneNumber, // <--- إضافة الحقل الجديد
    this.rating,
    this.ratingCount,
  });

  // Factory constructor to create a UserModel from a Firestore document
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      userType: (data['userType'] == 'broker') ? UserType.broker : UserType.buyer,
      location: data['location'],
      address: data['address'], // <--- إضافة الحقل الجديد
      phoneNumber: data['phoneNumber'], // <--- إضافة الحقل الجديد
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] ?? 0,
    );
  }

  // Method to convert a UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'userType': userType.toString().split('.').last,
      'location': location,
      'address': address, // <--- إضافة الحقل الجديد
      'phoneNumber': phoneNumber, // <--- إضافة الحقل الجديد
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }
}