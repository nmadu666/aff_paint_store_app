import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';

/// Provider cho instance của FirebaseAuth.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Provider cho AuthRepository.
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
});

/// Provider để theo dõi sự thay đổi trạng thái đăng nhập.
///
/// Widget nào `watch` provider này sẽ tự động được build lại khi người dùng
/// đăng nhập hoặc đăng xuất.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

