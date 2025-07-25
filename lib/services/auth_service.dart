import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user stream
  Stream<User?> get user => _auth.authStateChanges();

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle(UserType userType, String? location, String? address, String? phoneNumber) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Check if user already exists in Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // Create new user in Firestore
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            userType: userType,
            location: location,
            address: address, // <--- إضافة الحقل الجديد
            phoneNumber: phoneNumber, // <--- إضافة الحقل الجديد
            rating: (userType == UserType.broker) ? 0.0 : null,
            ratingCount: (userType == UserType.broker) ? 0 : null,
          );
          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
          return newUser;
        } else {
          return UserModel.fromDocument(userDoc);
        }
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Phone authentication - Step 1: Verify Phone Number
  Future<void> verifyPhoneNumber(String phoneNumber, Function(PhoneAuthCredential) verificationCompleted,
      Function(FirebaseAuthException) verificationFailed, Function(String, int?) codeSent,
      Function(String) codeAutoRetrievalTimeout) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // Phone authentication - Step 2: Sign in with Credential
  Future<UserModel?> signInWithPhoneCredential(PhoneAuthCredential credential, String name, UserType userType, String? photoUrl, String? location, String? address) async {
    try {
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.phoneNumber ?? '', // Use phone number as email for phone auth users
            name: name,
            photoUrl: photoUrl,
            userType: userType,
            location: location,
            address: address, // <--- إضافة الحقل الجديد
            phoneNumber: user.phoneNumber, // <--- استخدام رقم الهاتف من Firebase Auth
            rating: (userType == UserType.broker) ? 0.0 : null,
            ratingCount: (userType == UserType.broker) ? 0 : null,
          );
          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
          return newUser;
        } else {
          return UserModel.fromDocument(userDoc);
        }
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String uid, {String? name, String? location, String? address, String? phoneNumber, String? photoUrl}) async {
    try {
      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (location != null) updateData['location'] = location;
      if (address != null) updateData['address'] = address;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(uid).update(updateData);
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google as well
      await _auth.signOut();
      // Clear any stored user data if necessary
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print(e.toString());
    }
  }
}