import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authRepository) {
    _currentUser = _authRepository.currentUser;
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authRepository.signIn(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password, {String? location}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // Register the account but don't log the user in.
      // User must sign in separately after account creation.
      await _authRepository.signUp(name: name, email: email, password: password, location: location);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authRepository.signOut();
    _currentUser = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


// //version 2 all working with small signup glitch 

// import 'dart:async';

// import 'package:flutter/foundation.dart';

// import '../models/user_model.dart';
// import '../repositories/auth_repository.dart';

// class AuthProvider extends ChangeNotifier {
//   final AuthRepository _authRepository;

//   UserModel? _currentUser;
//   bool _isLoading = false;
//   String? _errorMessage;

//   StreamSubscription<UserModel?>? _authSubscription;

//   AuthProvider(this._authRepository) {
//     _currentUser = _authRepository.currentUser;

//     _authSubscription = _authRepository.authStateChanges.listen((user) {
//       _currentUser = user;
//       notifyListeners();
//     });
//   }

//   UserModel? get currentUser => _currentUser;

//   bool get isAuthenticated => _currentUser != null;

//   bool get isLoading => _isLoading;

//   String? get errorMessage => _errorMessage;

//   void clearError() {
//     _errorMessage = null;
//     notifyListeners();
//   }

//   Future<bool> signIn(
//     String email,
//     String password,
//   ) async {
//     _setLoading(true);
//     _errorMessage = null;

//     try {
//       _currentUser = await _authRepository.signIn(
//         email: email,
//         password: password,
//       );

//       _setLoading(false);
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceAll('Exception: ', '');

//       _setLoading(false);
//       return false;
//     }
//   }

//   Future<bool> signUp(
//     String name,
//     String email,
//     String password, {
//     String? location,
//   }) async {
//     _setLoading(true);
//     _errorMessage = null;

//     try {
//       _currentUser = await _authRepository.signUp(
//         name: name,
//         email: email,
//         password: password,
//         location: location,
//       );

//       _setLoading(false);
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceAll('Exception: ', '');

//       _setLoading(false);
//       return false;
//     }
//   }

//   Future<bool> sendPasswordResetEmail(
//     String email,
//   ) async {
//     _setLoading(true);
//     _errorMessage = null;

//     try {
//       await _authRepository.sendPasswordResetEmail(
//         email: email,
//       );

//       _setLoading(false);
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceAll('Exception: ', '');

//       _setLoading(false);
//       return false;
//     }
//   }

//   Future<void> signOut() async {
//     _setLoading(true);
//     _errorMessage = null;

//     try {
//       await _authRepository.signOut();
//       _currentUser = null;
//     } catch (e) {
//       _errorMessage = e.toString().replaceAll('Exception: ', '');
//     }

//     _setLoading(false);
//   }

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _authSubscription?.cancel();
//     super.dispose();
//   }
// }

