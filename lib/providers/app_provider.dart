import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/capture_item.dart';
import '../models/deadline.dart';
import '../models/action_suggestion.dart';
import '../models/daily_brief.dart';
import '../services/storage_service.dart';
import '../services/ocr_service.dart';
import '../services/search_service.dart';
import '../services/categorisation_service.dart';
import '../services/extraction_service.dart';
import '../services/deadline_service.dart';
import '../services/action_service.dart';
import '../services/brief_service.dart';
import '../services/photo_import_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final OcrService _ocr = OcrService();
  final SearchService _search = SearchService();
  final CategorisationService _categorisation = CategorisationService();
  final ExtractionService _extraction = ExtractionService();
  final ActionService _actionService = ActionService();
  late final DeadlineService _deadlineService;
  late final BriefService _briefService;
  final PhotoImportService _photoImport = PhotoImportService();
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  List<CaptureItem> _items = [];
  List<SearchResult> _searchResults = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isImporting = false;
  ImportProgress? _importProgress;
  int _currentTab = 0;

  // Intelligence layer
  DailyBrief? _brief;
  List<Deadline> _urgentDeadlines = [];
  List<Deadline> _upcomingDeadlines = [];
  List<Deadline> _expiredDeadlines = [];
  List<ActionSuggestion> _pendingActions = [];

  AppProvider() {
    _deadlineService = DeadlineService(_storage);
    _briefService = BriefService(_deadlineService, _actionService);
  }

  // Getters
  List<CaptureItem> get items => _items;
  List<CaptureItem> get activeItems =>
      _items.where((i) => !i.isArchived).toList();
  List<CaptureItem> get pinnedItems =>
      activeItems.where((i) => i.isPinned).toList();
  List<CaptureItem> get recentItems =>
      activeItems.take(20).toList();
  List<SearchResult> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  bool get isImporting => _isImporting;
  ImportProgress? get importProgress => _importProgress;
  int get currentTab => _currentTab;
  int get totalItems => activeItems.length;
  StorageService get storage => _storage;

  // Intelligence getters
  DailyBrief? get brief => _brief;
  List<Deadline> get urgentDeadlines => _urgentDeadlines;
  List<Deadline> get upcomingDeadlines => _upcomingDeadlines;
  List<Deadline> get expiredDeadlines => _expiredDeadlines;
  List<ActionSuggestion> get pendingActions => _pendingActions;
  bool get hasAlerts =>
      _expiredDeadlines.isNotEmpty || _urgentDeadlines.isNotEmpty;

  Map<ItemCategory, int> get categoryCounts {
    final counts = <ItemCategory, int>{};
    for (final item in activeItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  List<MapEntry<ItemCategory, int>> get activeCategories {
    final entries = categoryCounts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storage.init();
    _items = _storage.getAllItems();

    _isLoading = false;
    notifyListeners();

    // Process unprocessed items and build intelligence
    _processUnprocessedItems();
    _refreshIntelligence();
  }

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  // --- Intelligence Layer ---

  void _refreshIntelligence() {
    final active = activeItems;
    _urgentDeadlines = _deadlineService.getUrgent(active);
    _upcomingDeadlines = _deadlineService.getUpcoming(active);
    _expiredDeadlines = _deadlineService.getExpired(active);
    _pendingActions = _actionService.getAllPendingActions(active).take(15).toList();
    _brief = _briefService.generate(active);
    notifyListeners();
  }

  /// Get action suggestions for a specific item.
  List<ActionSuggestion> getActionsForItem(String itemId) {
    final item = _items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return [];
    return _actionService.generateActions(item);
  }

  /// Dismiss a deadline.
  Future<void> dismissDeadline(String deadlineId) async {
    await _deadlineService.dismissDeadline(deadlineId);
    _refreshIntelligence();
  }

  // --- Search ---

  void search(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _search.search(activeItems, query);
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // --- Capture ---

  Future<CaptureItem?> captureFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null) return null;
    return _createImageItem(photo.path, CaptureType.photo);
  }

  Future<CaptureItem?> captureFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return null;
    return _createImageItem(image.path, CaptureType.photo);
  }

  Future<List<CaptureItem>> captureMultipleFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
    final items = <CaptureItem>[];
    for (final image in images) {
      final item = await _createImageItem(image.path, CaptureType.photo);
      if (item != null) items.add(item);
    }
    return items;
  }

  Future<CaptureItem> captureNote(String text, {String? title}) async {
    final item = CaptureItem(
      id: _uuid.v4(),
      title: title,
      rawText: text,
      type: CaptureType.note,
      isProcessed: true,
    );

    // Auto-categorise and extract intelligence
    item.category = _categorisation.categorise(text);
    final extraction = _extraction.extract(text);
    item.extractedData = extraction.toMap();

    await _storage.saveItem(item);
    _items.insert(0, item);
    _refreshIntelligence();
    notifyListeners();
    return item;
  }

  Future<CaptureItem> captureClipboard(String text) async {
    final item = CaptureItem(
      id: _uuid.v4(),
      rawText: text,
      type: CaptureType.clipboard,
      isProcessed: true,
    );

    item.category = _categorisation.categorise(text);
    final extraction = _extraction.extract(text);
    item.extractedData = extraction.toMap();

    await _storage.saveItem(item);
    _items.insert(0, item);
    _refreshIntelligence();
    notifyListeners();
    return item;
  }

  Future<CaptureItem?> _createImageItem(String path, CaptureType type) async {
    final item = CaptureItem(
      id: _uuid.v4(),
      filePath: path,
      type: type,
      isProcessed: false,
    );

    await _storage.saveItem(item);
    _items.insert(0, item);
    notifyListeners();

    // Process OCR in background
    _processItem(item);
    return item;
  }

  // --- Processing ---

  Future<void> _processItem(CaptureItem item) async {
    if (item.isProcessed || item.filePath == null) return;

    try {
      final result = await _ocr.processImage(item.filePath!);
      if (result.isNotEmpty) {
        item.rawText = result.fullText;
        item.category = _categorisation.categorise(result.fullText);

        // Use the smart extraction service
        final extraction = _extraction.extract(result.fullText);
        item.extractedData = extraction.toMap();
      }
    } catch (e) {
      debugPrint('OCR failed for ${item.id}: $e');
    }

    item.isProcessed = true;
    await _storage.updateItem(item);
    _refreshIntelligence();
    notifyListeners();
  }

  Future<void> _processUnprocessedItems() async {
    final unprocessed = _items.where((i) => !i.isProcessed).toList();
    if (unprocessed.isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    for (final item in unprocessed) {
      await _processItem(item);
    }

    _isProcessing = false;
    _refreshIntelligence();
    notifyListeners();
  }

  // --- Device Photo Import ---

  Future<bool> requestPhotoPermission() async {
    return _photoImport.requestPermission();
  }

  Future<int> getDevicePhotoCount() async {
    return _photoImport.getDevicePhotoCount();
  }

  Future<void> importDevicePhotos() async {
    if (_isImporting) return;

    _isImporting = true;
    _importProgress = null;
    notifyListeners();

    final existingPaths = _items
        .where((i) => i.filePath != null)
        .map((i) => i.filePath!)
        .toSet();

    await for (final progress in _photoImport.importDevicePhotos(
      storage: _storage,
      existingFilePaths: existingPaths,
    )) {
      _importProgress = progress;
      notifyListeners();

      if (progress.status == ImportStatus.complete) {
        // Reload all items from storage
        _items = _storage.getAllItems();
        _isImporting = false;
        _refreshIntelligence();
        notifyListeners();
      }
    }
  }

  void cancelImport() {
    _isImporting = false;
    _importProgress = null;
    notifyListeners();
  }

  /// Reload all items from storage (after file import, etc.)
  void reloadItems() {
    _items = _storage.getAllItems();
    _refreshIntelligence();
    notifyListeners();
  }

  // --- Item Management ---

  Future<void> updateItem(CaptureItem item) async {
    await _storage.updateItem(item);
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) _items[idx] = item;
    _refreshIntelligence();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final item = _items.firstWhere((i) => i.id == id);
    // Delete file if exists
    if (item.filePath != null) {
      try {
        await File(item.filePath!).delete();
      } catch (_) {}
    }
    await _storage.deleteItem(id);
    _items.removeWhere((i) => i.id == id);
    _refreshIntelligence();
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    final item = _items.firstWhere((i) => i.id == id);
    item.isPinned = !item.isPinned;
    await _storage.updateItem(item);
    notifyListeners();
  }

  Future<void> archiveItem(String id) async {
    final item = _items.firstWhere((i) => i.id == id);
    item.isArchived = true;
    await _storage.updateItem(item);
    _refreshIntelligence();
    notifyListeners();
  }

  List<CaptureItem> getItemsByCategory(ItemCategory category) {
    return activeItems.where((i) => i.category == category).toList();
  }

  List<CaptureItem> getItemsByType(CaptureType type) {
    return activeItems.where((i) => i.type == type).toList();
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }
}
