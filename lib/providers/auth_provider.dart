import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _verificationId; // For phone authentication

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get verificationId => _verificationId;

  // Listen to auth state changes
  void initializeAuthListener() {
    _authService.user.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getUserData(firebaseUser.uid);
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  // Sign in with Google
  Future<bool> signInWithGoogle(UserType userType, String? location, String? address, String? phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserModel? newUser = await _authService.signInWithGoogle(userType, location, address, phoneNumber);
      _user = newUser;
      _isLoading = false;
      notifyListeners();
      return newUser != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print(e.toString());
      return false;
    }
  }

  // Phone authentication - Step 1: Send verification code
  Future<bool> sendPhoneVerificationCode(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber,
        (PhoneAuthCredential credential) async {
          // Auto-verification completed
          // This happens on some Android devices when SMS is automatically read
          _isLoading = false;
          notifyListeners();
        },
        (FirebaseAuthException e) {
          // Verification failed
          _isLoading = false;
          notifyListeners();
          print('Phone verification failed: ${e.message}');
        },
        (String verificationId, int? resendToken) {
          // Code sent successfully
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
        },
        (String verificationId) {
          // Auto-retrieval timeout
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
        },
      );
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print(e.toString());
      return false;
    }
  }

  // Phone authentication - Step 2: Verify code and sign in
  Future<bool> verifyPhoneCodeAndSignIn(String smsCode, String name, UserType userType, String? photoUrl, String? location, String? address) async {
    if (_verificationId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserModel? newUser = await _authService.signInWithPhoneCredential(credential, name, userType, photoUrl, location, address);
      _user = newUser;
      _isLoading = false;
      notifyListeners();
      return newUser != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print(e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _verificationId = null;
      notifyListeners();
    } catch (e) {
      print(e.toString());
    }
  }
}