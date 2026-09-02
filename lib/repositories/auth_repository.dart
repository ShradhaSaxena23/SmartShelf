import '../models/user_model.dart';

abstract class AuthRepository {
  UserModel? get currentUser;
  Stream<UserModel?> get authStateChanges;
  
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({required String name, required String email, required String password, String? location});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
}
