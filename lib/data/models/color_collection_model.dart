import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a collection of colors, e.g., "Mykolor 2024 Collection".
class ColorCollection {
  final String id;
  final String name;
  final String? description;

  /// ID of the document in the 'trademarks' collection.
  final String trademarkRef;

  /// List of color document IDs belonging to this collection.
  final List<String> colorRefs;

  ColorCollection({
    required this.id,
    required this.name,
    this.description,
    required this.trademarkRef,
    required this.colorRefs,
  });

  factory ColorCollection.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw "ColorCollection data does not exist for snapshot: ${snapshot.id}";
    }

    return ColorCollection(
      id: snapshot.id,
      name: data['name'] ?? '',
      description: data['description'],
      trademarkRef: data['trademark_ref'] ?? '',
      colorRefs: data['color_refs'] != null
          ? List<String>.from(data['color_refs'])
          : [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'trademark_ref': trademarkRef,
      'color_refs': colorRefs,
    };
  }
}
