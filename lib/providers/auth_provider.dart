import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

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

  // Register
  Future<bool> register(String email, String password, String name, UserType userType, String? photoUrl, String? location) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserModel? newUser = await _authService.registerWithEmailAndPassword(
          email, password, name, userType, photoUrl, location);
      if (newUser != null) {
        _user = newUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e.toString());
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserModel? user = await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        _user = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e.toString());
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  // Update user data
  Future<void> updateUser(Map<String, dynamic> data) async {
    if (_user != null) {
      await _authService.updateUserData(_user!.uid, data);
      _user = await _authService.getUserData(_user!.uid);
      notifyListeners();
    }
  }
}