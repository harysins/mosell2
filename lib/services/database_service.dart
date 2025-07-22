import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new property
  Future<void> addProperty(PropertyModel property) async {
    try {
      await _firestore.collection('properties').add(property.toMap());
    } catch (e) {
      print(e.toString());
      return Future.error(e.toString());
    }
  }

  // Get all properties
  Stream<List<PropertyModel>> getProperties() {
    return _firestore.collection('properties').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PropertyModel.fromDocument(doc)).toList();
    });
  }

  // Get properties by broker ID
  Stream<List<PropertyModel>> getBrokerProperties(String brokerId) {
    return _firestore.collection('properties').where('brokerId', isEqualTo: brokerId).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PropertyModel.fromDocument(doc)).toList();
    });
  }

  // Update property
  Future<void> updateProperty(String propertyId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update(data);
    } catch (e) {
      print(e.toString());
      return Future.error(e.toString());
    }
  }

  // Delete property
  Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).delete();
    } catch (e) {
      print(e.toString());
      return Future.error(e.toString());
    }
  }

  // Add a rating to a broker
  Future<void> addBrokerRating(String brokerId, double newRating) async {
    try {
      DocumentReference brokerRef = _firestore.collection('users').doc(brokerId);
      return _firestore.runTransaction((transaction) async {
        DocumentSnapshot brokerSnapshot = await transaction.get(brokerRef);
        if (!brokerSnapshot.exists) {
          throw Exception("Broker does not exist!");
        }

        UserModel broker = UserModel.fromDocument(brokerSnapshot);
        double currentRating = broker.rating ?? 0.0;
        int ratingCount = broker.ratingCount ?? 0;

        double updatedRating = (currentRating * ratingCount + newRating) / (ratingCount + 1);
        int updatedRatingCount = ratingCount + 1;

        transaction.update(brokerRef, {
          'rating': updatedRating,
          'ratingCount': updatedRatingCount,
        });
      });
    } catch (e) {
      print(e.toString());
      return Future.error(e.toString());
    }
  }
}