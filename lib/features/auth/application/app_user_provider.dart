import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/models/branch_model.dart';
import '../../../data/models/app_user_model.dart';
import '../../../data/models/kiotviet_user_model.dart';
import '../../../data/repositories/user_repository.dart';
import 'auth_providers.dart';
import '../../../data/repositories/kiotviet_user_repository.dart';
import '../../../data/repositories/branch_repository.dart';

/// Provider cho IUserRepository.
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return FirebaseUserRepository(FirebaseFirestore.instance);
});

/// Provider này theo dõi trạng thái đăng nhập từ Firebase Auth (`authStateChangesProvider`)
/// Provider cho IKiotVietUserRepository.
final kiotVietUserRepositoryProvider = Provider<IKiotVietUserRepository>((ref) {
  return FirebaseKiotVietUserRepository(FirebaseFirestore.instance);
});

/// Provider cho IBranchRepository.
final branchRepositoryProvider = Provider<IBranchRepository>((ref) {
  return FirebaseBranchRepository(FirebaseFirestore.instance);
});

/// Provider này theo dõi trạng thái đăng nhập từ Firebase Auth (`authStateChangesProvider`)
/// và sau đó tìm nạp đối tượng `AppUser` tương ứng từ Firestore.
///
/// Kết quả là một `AsyncValue<AppUser?>`:
/// - `AsyncData(AppUser)`: Người dùng đã đăng nhập và dữ liệu của họ đã được tải.
/// - `AsyncData(null)`: Người dùng đã đăng xuất.
/// - `AsyncLoading`: Đang trong quá trình xác thực hoặc tải dữ liệu.
/// - `AsyncError`: Có lỗi xảy ra.
final appUserProvider = FutureProvider<AppUser?>((ref) async {
  // Lắng nghe trạng thái người dùng từ Firebase Auth.
  final firebaseUser = ref.watch(authStateChangesProvider).value;

  if (firebaseUser != null) {
    // Nếu người dùng đã đăng nhập, lấy thông tin chi tiết từ UserRepository.
    final userRepository = ref.read(userRepositoryProvider);
    final appUser = await userRepository.getUser(firebaseUser.uid);
    if (appUser == null) {
      // Trường hợp này có thể xảy ra nếu tài khoản auth tồn tại nhưng
      // document trong 'users' collection chưa được tạo.
      // Bạn có thể xử lý bằng cách đăng xuất người dùng hoặc hiển thị lỗi.
      throw Exception(
        'Không tìm thấy dữ liệu người dùng cho UID: ${firebaseUser.uid}',
      );
    }
    return appUser;
  } else {
    // Nếu không có người dùng nào đăng nhập.
    return null;
  }
});

/// Provider này lấy thông tin chi tiết của `KiotVietUser` liên quan đến
/// `AppUser` đang đăng nhập.
///
/// Nó lắng nghe `appUserProvider` và sử dụng `kiotVietUserRef` để truy vấn
/// dữ liệu từ `kiotviet_users` collection.
///
/// Kết quả là một `AsyncValue<KiotVietUser?>`:
/// - `AsyncData(KiotVietUser)`: Người dùng đã đăng nhập và thông tin KiotViet của họ đã được tải.
/// - `AsyncData(null)`: Người dùng chưa đăng nhập, hoặc không có tham chiếu đến KiotViet user.
/// - `AsyncLoading`: Đang tải dữ liệu.
/// - `AsyncError`: Có lỗi xảy ra.
final kiotVietUserProvider = FutureProvider<KiotVietUser?>((ref) async {
  // Lắng nghe provider người dùng ứng dụng.
  final appUser = ref.watch(appUserProvider).value;

  // Nếu không có người dùng ứng dụng hoặc không có tham chiếu, trả về null.
  if (appUser == null || appUser.kiotVietUserRef == null) {
    return null;
  }

  // Lấy repository và truy vấn thông tin KiotViet user.
  final kiotVietUserRepository = ref.read(kiotVietUserRepositoryProvider);
  return await kiotVietUserRepository.getKiotVietUserById(
    appUser.kiotVietUserRef!.id,
  );
});

/// Provider này lấy thông tin chi tiết của `Branch` (chi nhánh) mà `AppUser`
/// đang đăng nhập được gán vào.
///
/// Nó lắng nghe `appUserProvider` và sử dụng `branchRef` (một DocumentReference)
/// để truy vấn dữ liệu từ collection `branches`.
///
/// Kết quả là một `AsyncValue<Branch?>`:
/// - `AsyncData(Branch)`: Thông tin chi nhánh đã được tải thành công.
/// - `AsyncData(null)`: Người dùng chưa đăng nhập, hoặc không được gán vào chi nhánh nào.
/// - `AsyncLoading`: Đang tải dữ liệu.
/// - `AsyncError`: Có lỗi xảy ra.
final branchProvider = FutureProvider<Branch?>((ref) async {
  // Lắng nghe provider người dùng ứng dụng.
  final appUser = ref.watch(appUserProvider).value;

  // Nếu không có người dùng hoặc không có tham chiếu chi nhánh, trả về null.
  if (appUser == null || appUser.branchRef == null) {
    return null;
  }

  // Lấy repository và truy vấn thông tin chi nhánh bằng ID từ DocumentReference.
  final branchRepository = ref.read(branchRepositoryProvider);
  return await branchRepository.getBranchById(appUser.branchRef!.id);
});

/// Provider để lấy danh sách tất cả các chi nhánh.
/// Dùng cho dropdown trong trang chỉnh sửa thông tin.
final allBranchesProvider = FutureProvider<List<Branch>>((ref) async {
  final branchRepository = ref.read(branchRepositoryProvider);
  return branchRepository.getAllBranches();
});

/// Provider để lấy danh sách tất cả người dùng KiotViet.
/// Dùng cho dropdown trong trang chỉnh sửa thông tin.
final allKiotVietUsersProvider = FutureProvider<List<MapEntry<String, String>>>(
  (ref) async {
    final kiotVietUserRepository = ref.read(kiotVietUserRepositoryProvider);
    return kiotVietUserRepository.getAllKiotVietUsersAsMap();
  },
);

/// Provider để lấy danh sách tất cả các AppUser trong hệ thống.
final allAppUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  final userRepository = ref.read(userRepositoryProvider);
  return userRepository.getAllUsers();
});
