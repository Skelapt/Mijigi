import 'package:hive_flutter/hive_flutter.dart';
import '../models/capture_item.dart';

class StorageService {
  static const _boxName = 'captures';
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  List<CaptureItem> getAllItems() {
    return _box.values
        .map((e) => CaptureItem.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<CaptureItem> getActiveItems() {
    return getAllItems().where((item) => !item.isArchived).toList();
  }

  List<CaptureItem> getItemsByCategory(ItemCategory category) {
    return getActiveItems().where((item) => item.category == category).toList();
  }

  List<CaptureItem> getItemsByType(CaptureType type) {
    return getActiveItems().where((item) => item.type == type).toList();
  }

  List<CaptureItem> getPinnedItems() {
    return getActiveItems().where((item) => item.isPinned).toList();
  }

  List<CaptureItem> getUnprocessedItems() {
    return getAllItems().where((item) => !item.isProcessed).toList();
  }

  CaptureItem? getItem(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return CaptureItem.fromMap(Map<dynamic, dynamic>.from(raw as Map));
  }

  Future<void> saveItem(CaptureItem item) async {
    await _box.put(item.id, item.toMap());
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
  }

  Future<void> updateItem(CaptureItem item) async {
    await saveItem(item);
  }

  int get totalItems => _box.length;

  Map<ItemCategory, int> getCategoryCounts() {
    final items = getActiveItems();
    final counts = <ItemCategory, int>{};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  Map<CaptureType, int> getTypeCounts() {
    final items = getActiveItems();
    final counts = <CaptureType, int>{};
    for (final item in items) {
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }
    return counts;
  }
}
