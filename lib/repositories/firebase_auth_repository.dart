import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  UserModel? _currentUser;

  final StreamController<UserModel?> _controller =
      StreamController<UserModel?>.broadcast();

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _listenToFirebaseAuth();
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  void _listenToFirebaseAuth() {
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _controller.add(null);
        return;
      }

      try {
        final userModel = await _getUserModel(firebaseUser);

        _currentUser = userModel;
        _controller.add(userModel);
      } catch (e) {
        // If the Firebase Auth user exists but the Firestore profile
        // doesn't exist, create a basic UserModel from Firebase Auth.
        final fallbackUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          phoneNumber: firebaseUser.phoneNumber,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );

        _currentUser = fallbackUser;
        _controller.add(fallbackUser);
      }
    });
  }

  Future<UserModel> _getUserModel(User firebaseUser) async {
    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      return UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        phoneNumber: firebaseUser.phoneNumber,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );
    }

    final data = doc.data()!;

    DateTime createdAt;

    final createdAtValue = data['createdAt'];

    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else {
      createdAt =
          firebaseUser.metadata.creationTime ?? DateTime.now();
    }

    return UserModel(
      uid: firebaseUser.uid,
      email: data['email'] as String? ?? firebaseUser.email ?? '',
      displayName:
          data['displayName'] as String? ??
          firebaseUser.displayName ??
          '',
      phoneNumber:
          data['phoneNumber'] as String? ??
          firebaseUser.phoneNumber,
      location: data['location'] as String?,
      createdAt: createdAt,
    );
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Unable to sign in. Please try again.');
      }

      final userModel = await _getUserModel(firebaseUser);

      _currentUser = userModel;
      _controller.add(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String? location,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final trimmedName = name.trim();
      final trimmedLocation = location?.trim();

      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception(
          'Unable to create your account. Please try again.',
        );
      }

      // Store the user's display name in Firebase Authentication.
      await firebaseUser.updateDisplayName(trimmedName);

      final createdAt =
          firebaseUser.metadata.creationTime ?? DateTime.now();

      // Store application-specific user information in Firestore.
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': normalizedEmail,
        'displayName': trimmedName,
        'phoneNumber': firebaseUser.phoneNumber,
        'location':
            trimmedLocation != null && trimmedLocation.isNotEmpty
                ? trimmedLocation
                : null,
        'createdAt': Timestamp.fromDate(createdAt),
      });

      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: normalizedEmail,
        displayName: trimmedName,
        phoneNumber: firebaseUser.phoneNumber,
        location:
            trimmedLocation != null && trimmedLocation.isNotEmpty
                ? trimmedLocation
                : null,
        createdAt: createdAt,
      );

      _currentUser = userModel;
      _controller.add(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      await _firebaseAuth.sendPasswordResetEmail(
        email: normalizedEmail,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();

      _currentUser = null;
      _controller.add(null);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';

      case 'user-not-found':
        return 'No account found with this email. Please create an account first.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in.';

      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';

      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled. Please enable it in Firebase Console.';

      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'requires-recent-login':
        return 'Please sign in again before performing this action.';

      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  void dispose() {
    _controller.close();
  }
}

