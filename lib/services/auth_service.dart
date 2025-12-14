import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register new user
  Future<UserModel?> registerUser({
    required String name,
    required DateTime dob,
    required String email,
    required String password,
  }) async {
    try {
      // Create Firebase Auth account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure user is not null
      if (userCredential.user == null) {
        throw 'Failed to create user account';
      }

      // Create user profile
      UserModel userModel = UserModel(
        userId: userCredential.user!.uid,
        name: name,
        dob: dob,
        email: email,
        createdAt: DateTime.now(),
        groupIds: [],
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      throw 'Database error: ${e.message ?? e.toString()}';
    } catch (e) {
      // Error already handled by throw
      throw 'Registration failed. Please try again.';
    }
  }

  // Login user
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromSnapshot(doc);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Login failed: ${e.toString()}';
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Logout failed: ${e.toString()}';
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user data: ${e.toString()}';
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.userId)
          .update(user.toMap());
    } catch (e) {
      throw 'Failed to update profile: ${e.toString()}';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
