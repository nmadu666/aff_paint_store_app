import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/color_collection_model.dart';
import '../../../../data/models/color_data_model.dart';
import '../../../../data/models/trademark_model.dart';
import '../../../colors/application/color_collection_providers.dart';
import '../../../colors/application/color_providers.dart';
import '../../../colors/application/trademark_providers.dart';

/// Hàm tiện ích để chuyển đổi chuỗi hex thành đối tượng Color của Flutter.
Color _hexToColor(String hexCode) {
  final buffer = StringBuffer();
  if (hexCode.length == 6 || hexCode.length == 7) buffer.write('ff');
  buffer.write(hexCode.replaceFirst('#', ''));
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return Colors.grey;
  }
}

class ColorLookupDrawer extends ConsumerStatefulWidget {
  final ValueChanged<ColorData> onColorSelected;

  const ColorLookupDrawer({super.key, required this.onColorSelected});

  @override
  ConsumerState<ColorLookupDrawer> createState() => _ColorLookupDrawerState();
}

class _ColorLookupDrawerState extends ConsumerState<ColorLookupDrawer> {
  String? _selectedTrademarkId;
  String? _selectedCollectionId;
  String _searchTerm = '';
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchTerm != _searchController.text.toLowerCase()) {
        setState(() {
          _searchTerm = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trademarksAsync = ref.watch(allTrademarksProvider);
    // Lọc danh sách bộ sưu tập dựa trên thương hiệu đã chọn.
    final collectionsAsync = ref.watch(colorCollectionsProvider(_selectedTrademarkId));
    final colorsAsync = ref.watch(allColorsProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Tra cứu màu', style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Trademark Filter
                  trademarksAsync.when(
                    data: (trademarks) => _buildDropdown<Trademark>(
                      items: trademarks,
                      value: _selectedTrademarkId,
                      hint: 'Tất cả thương hiệu',
                      onChanged: (id) => setState(() {
                        // Khi đổi thương hiệu, reset bộ lọc bộ sưu tập.
                        _selectedTrademarkId = id;
                        _selectedCollectionId = null;
                      }),
                      itemBuilder: (item) => DropdownMenuItem(value: item.id, child: Text(item.name)),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Lỗi tải thương hiệu: $e'),
                  ),
                  const SizedBox(height: 8),
                  // Collection Filter
                  collectionsAsync.when(
                    data: (collections) => _buildDropdown<ColorCollection>(
                      items: collections,
                      value: _selectedCollectionId,
                      hint: 'Tất cả bộ sưu tập',
                      onChanged: (id) => setState(() => _selectedCollectionId = id),
                      itemBuilder: (item) => DropdownMenuItem(value: item.id, child: Text(item.name)),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => Text('Lỗi tải BST: $e'),
                  ),
                  const SizedBox(height: 8),
                  // Search Field
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Tìm theo mã hoặc tên màu',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: colorsAsync.when(
                data: (allColors) {
                  final filteredColors = _getFilteredColors(allColors);
                  if (filteredColors.isEmpty) {
                    return const Center(child: Text('Không tìm thấy màu phù hợp.'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: filteredColors.length,
                    itemBuilder: (context, index) {
                      final color = filteredColors[index];
                      return _ColorTile(
                        color: color,
                        onTap: () => widget.onColorSelected(color),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Lỗi tải danh sách màu: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tách logic lọc ra khỏi hàm build để code rõ ràng hơn.
  List<ColorData> _getFilteredColors(List<ColorData> allColors) {
    if (_selectedTrademarkId == null &&
        _selectedCollectionId == null &&
        _searchTerm.isEmpty) {
      return allColors;
    }
    return allColors.where((color) {
      final trademarkMatch = _selectedTrademarkId == null || color.trademarkRef == _selectedTrademarkId;
      final collectionMatch = _selectedCollectionId == null || color.collectionRefs.any((ref) => ref == _selectedCollectionId);
      final searchMatch = _searchTerm.isEmpty || color.code.toLowerCase().contains(_searchTerm) || color.name.toLowerCase().contains(_searchTerm);
      return trademarkMatch && collectionMatch && searchMatch;
    }).toList();
  }

  Widget _buildDropdown<T>({
    required List<T> items,
    required String? value,
    required String hint,
    required void Function(String?) onChanged,
    required DropdownMenuItem<String> Function(T) itemBuilder,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      hint: Text(hint),
      isExpanded: true,
      items: [
        DropdownMenuItem<String>(value: null, child: Text(hint)),
        ...items.map(itemBuilder),
      ],
      onChanged: onChanged,
    );
  }
}

class _ColorTile extends StatelessWidget {
  final ColorData color;
  final VoidCallback onTap;

  const _ColorTile({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorSwatch = _hexToColor(color.hexCode);
    final textColor = colorSwatch.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        child: Container(
          color: colorSwatch,
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.bottomCenter,
          child: Text(
            color.code,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
