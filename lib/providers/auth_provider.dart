import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get needsPrivacyAccept => _user != null && !_user!.privacyAccepted;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
    } else {
      _status = AuthStatus.loading;
      notifyListeners();

      final userData = await _authService.getUserData(firebaseUser.uid);
      if (userData == null) {
        // Only reject if we definitively know email is NOT registered.
        // If null (network/permission error), allow through to avoid locking out valid users.
        final isRegistered = await _authService.isEmailRegisteredDirectly(firebaseUser.email ?? '');
        if (isRegistered == false) {
          // Definitely not registered — force sign out
          await _authService.signOut();
          _status = AuthStatus.unauthenticated;
          _user = null;
          notifyListeners();
          return;
        }
      }

      _user = userData;
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      _user = await _authService.getUserData(credential.user!.uid);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      if (_errorMessage!.startsWith('Exception: ')) {
        _errorMessage = _errorMessage!.substring(11);
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> acceptPrivacyPolicy() async {
    if (_user == null) return;
    await _authService.acceptPrivacyPolicy(_user!.uid);
    _user = _user!.copyWith(privacyAccepted: true);
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    await _authService.updateUserData(_user!.uid, data);
    _user = await _authService.getUserData(_user!.uid);
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    _user = await _authService.getUserData(_user!.uid);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}