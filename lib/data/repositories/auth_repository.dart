import 'package:firebase_auth/firebase_auth.dart';

/// Lớp trừu tượng định nghĩa các phương thức xác thực người dùng.
abstract class IAuthRepository {
  /// Một stream để theo dõi trạng thái đăng nhập của người dùng.
  Stream<User?> get authStateChanges;

  /// Lấy người dùng hiện tại (nếu có).
  User? get currentUser;

  /// Đăng nhập bằng email và mật khẩu.
  Future<void> signInWithEmailAndPassword(String email, String password);

  /// Tạo tài khoản mới bằng email và mật khẩu.
  Future<void> createUserWithEmailAndPassword(String email, String password);

  /// Đăng xuất.
  Future<void> signOut();
}

/// Triển khai repository sử dụng Firebase Authentication.
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

