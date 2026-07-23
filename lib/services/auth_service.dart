import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool?> _checkEmailRegistered(String email) async {
    try {
      final doc = await _firestore
          .collection('registered_emails')
          .doc(email.toLowerCase().trim())
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final data = doc.data();
        return data?['registered'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email registration in Firestore: $e');
      return null;
    }
  }

  Future<bool?> isEmailRegisteredDirectly(String email) async {
    if (email.isEmpty) return false;
    return await _checkEmailRegistered(email);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Authenticate with Firebase first to gain read access under Firestore security rules
      final userCredential = await _auth.signInWithCredential(credential);

      final isRegistered = await _checkEmailRegistered(googleUser.email);
      if (isRegistered == null) {
        await signOut();
        throw Exception('Connection error. Please check your internet connection.');
      }
      if (!isRegistered) {
        await signOut();
        throw Exception('Your email (${googleUser.email}) is not registered in the system. Please ask the hospital staff to register your email.');
      }

      await _createUserIfNotExists(userCredential.user!);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createUserIfNotExists(User firebaseUser) async {
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final user = UserModel(
        uid: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? 'Patient',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        privacyAccepted: false,
      );
      await docRef.set(user.toMap());
    }

    // Call the web backend to link the Firebase UID to the patient record
    try {
      final url = Uri.parse('${AppConstants.webBackendUrl}/api/auth/link-firebase');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_uid': firebaseUser.uid,
          'email': firebaseUser.email,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('Successfully linked Firebase UID to backend');
      } else {
        debugPrint('Backend link-firebase returned status: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to link Firebase UID to backend: $e');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(data);
  }

  Future<void> acceptPrivacyPolicy(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'privacyAccepted': true});
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
