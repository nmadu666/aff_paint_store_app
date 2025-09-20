import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/trademark_model.dart';
import '../../../data/repositories/trademark_repository.dart';

final trademarkRepositoryProvider = Provider<ITrademarkRepository>((ref) {
  return FirebaseTrademarkRepository();
});

final allTrademarksProvider = FutureProvider<List<Trademark>>((ref) {
  final repository = ref.watch(trademarkRepositoryProvider);
  return repository.getAllTrademarks();
});

