import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../models/trademark_model.dart';

/// Lớp trừu tượng định nghĩa các phương thức để lấy dữ liệu cho bộ lọc.
abstract class IFilterRepository {
  Future<List<Category>> getCategories();
  Future<List<Trademark>> getTrademarks();
}

/// Triển khai repository sử dụng Firebase Firestore.
class FirebaseFilterRepository implements IFilterRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await _firestore.collection('categories').orderBy('name').get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  @override
  Future<List<Trademark>> getTrademarks() async {
    final snapshot = await _firestore.collection('trademarks').orderBy('name').get();
    return snapshot.docs.map((doc) => Trademark.fromFirestore(doc)).toList();
  }
}

