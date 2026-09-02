import 'dart:async';
import '../models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final StreamController<UserModel?> _controller = StreamController<UserModel?>.broadcast();

  // In-memory registered user database for testing multi-tenant isolation locally
  final Map<String, Map<String, String>> _mockUsers = {
    'demo@smartshelf.com': {
      'uid': 'user_demo_123',
      'password': 'password123',
      'name': 'FreshTrack Demo User',
    }
  };

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    final normalizedEmail = email.trim().toLowerCase();

    if (_mockUsers.containsKey(normalizedEmail)) {
      final userData = _mockUsers[normalizedEmail]!;
      if (userData['password'] == password) {
        _currentUser = UserModel(
          uid: userData['uid']!,
          email: normalizedEmail,
          displayName: userData['name']!,
          createdAt: DateTime.now(),
        );
        _controller.add(_currentUser);
        return _currentUser!;
      } else {
        throw Exception('Invalid password for account.');
      }
    } else {
      throw Exception('No account found with this email. Please create an account first.');
    }
  }

  @override
  Future<UserModel> signUp({required String name, required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final normalizedEmail = email.trim().toLowerCase();

    // Prevent duplicate registration
    if (_mockUsers.containsKey(normalizedEmail)) {
      throw Exception('An account with this email already exists. Please sign in.');
    }

    final newUid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _mockUsers[normalizedEmail] = {
      'uid': newUid,
      'password': password,
      'name': name,
    };

    // Return the created user model but do NOT log them in.
    // User must sign in separately after account creation.
    return UserModel(
      uid: newUid,
      email: normalizedEmail,
      displayName: name,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simulated success
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _controller.add(null);
  }
}
