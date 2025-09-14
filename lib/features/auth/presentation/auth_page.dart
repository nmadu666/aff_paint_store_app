import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';

/// Enum để xác định chế độ của trang: Đăng nhập hoặc Đăng ký.
enum AuthMode { login, register }

/// Trang để người dùng đăng nhập hoặc đăng ký tài khoản.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  var _authMode = AuthMode.login;
  var _isLoading = false;
  String _email = '';
  String _password = '';

  /// Hàm xử lý logic khi người dùng nhấn nút submit.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return; // Nếu form không hợp lệ, không làm gì cả.
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      if (_authMode == AuthMode.login) {
        await authRepository.signInWithEmailAndPassword(_email, _password);
      } else {
        await authRepository.createUserWithEmailAndPassword(_email, _password);
      }
      // Nếu thành công, tự động quay lại trang trước.
      // authStateChangesProvider sẽ cập nhật UI của AccountPage.
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      // Hiển thị lỗi từ Firebase một cách thân thiện.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Đã xảy ra lỗi xác thực.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Chuyển đổi giữa chế độ Đăng nhập và Đăng ký.
  void _switchAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_authMode == AuthMode.login ? 'Đăng nhập' : 'Đăng ký'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  key: const ValueKey('email'),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Vui lòng nhập một địa chỉ email hợp lệ.';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  key: const ValueKey('password'),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự.';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value!,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                    ),
                    child: Text(_authMode == AuthMode.login ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ'),
                  ),
                TextButton(
                  onPressed: _switchAuthMode,
                  child: Text(
                    _authMode == AuthMode.login
                        ? 'Tạo tài khoản mới'
                        : 'Tôi đã có tài khoản',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

