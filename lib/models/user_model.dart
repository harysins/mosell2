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
  final double? rating;
  final int? ratingCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.userType,
    this.location,
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
      'userType': userType == UserType.broker ? 'broker' : 'buyer',
      'location': location,
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }

  // Method to create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    UserType? userType,
    String? location,
    double? rating,
    int? ratingCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}