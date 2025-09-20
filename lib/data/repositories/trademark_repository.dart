import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/trademark_model.dart';

abstract class ITrademarkRepository {
  Future<List<Trademark>> getAllTrademarks();
}

class FirebaseTrademarkRepository implements ITrademarkRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('trademarks');

  @override
  Future<List<Trademark>> getAllTrademarks() async {
    final snapshot = await _collection.orderBy('name').get();
    return snapshot.docs
        .map((doc) => Trademark.fromFirestore(doc))
        .toList();
  }
}

