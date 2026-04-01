import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/capture_item.dart';
import '../services/storage_service.dart';
import '../services/ocr_service.dart';
import '../services/labeling_service.dart';
import '../services/search_service.dart';
import '../services/categorisation_service.dart';
import '../services/photo_import_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final OcrService _ocr = OcrService();
  final LabelingService _labeling = LabelingService();
  final SearchService _search = SearchService();
  final CategorisationService _categorisation = CategorisationService();
  final PhotoImportService _photoImport = PhotoImportService();
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  List<CaptureItem> _items = [];
  final String _searchQuery = '';
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isImporting = false;
  ImportProgress? _importProgress;
  int _currentTab = 0;

  // Getters
  List<CaptureItem> get items => _items;
  List<CaptureItem> get activeItems =>
      _items.where((i) => !i.isArchived).toList();
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  bool get isImporting => _isImporting;
  ImportProgress? get importProgress => _importProgress;
  int get currentTab => _currentTab;
  int get totalItems => activeItems.length;
  StorageService get storage => _storage;

  String? _lastClipboardText;
  Timer? _clipboardTimer;
  bool _clipboardMonitorActive = false;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storage.init();
    _items = _storage.getAllItems();

    // Set _lastClipboardText from most recent saved clipboard item
    final recentClip = _items
        .where((i) => i.type == CaptureType.clipboard)
        .toList();
    if (recentClip.isNotEmpty) {
      _lastClipboardText = recentClip.first.rawText?.trim();
    }

    _isLoading = false;
    notifyListeners();

    _processUnprocessedItems();
    _autoImportPhotos();
    startClipboardMonitor();
  }

  /// Auto-import photos on startup (pro behaviour)
  Future<void> _autoImportPhotos() async {
    final hasPermission = await requestPhotoPermission();
    if (hasPermission) {
      importDevicePhotos();
    }
  }

  /// Start polling clipboard every 3 seconds
  void startClipboardMonitor() {
    if (_clipboardMonitorActive) return;
    _clipboardMonitorActive = true;
    _clipboardTimer?.cancel();
    _clipboardTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkClipboard();
    });
    // Also check immediately
    _checkClipboard();
  }

  /// Stop clipboard polling (when app goes to background)
  void stopClipboardMonitor() {
    _clipboardMonitorActive = false;
    _clipboardTimer?.cancel();
    _clipboardTimer = null;
  }

  /// Manual check - called from UI
  Future<void> checkClipboardNow() async {
    await _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) return;
      if (text == _lastClipboardText) return;

      _lastClipboardText = text;

      // Check not already saved
      final alreadySaved = _items.any((i) =>
          i.type == CaptureType.clipboard && i.rawText?.trim() == text);
      if (!alreadySaved) {
        debugPrint('[Mijigi] Auto-saving clipboard: ${text.length} chars');
        await captureClipboard(text);
      }
    } catch (e) {
      debugPrint('[Mijigi] Clipboard read failed: $e');
    }
  }

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  // --- Search ---

  List<SearchResult> searchImages(String query) {
    final images = activeItems.where((i) => i.isImageType).toList();
    return _search.search(images, query);
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

  Future<CaptureItem?> captureVideoFromCamera() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video == null) return null;
    return _createVideoItem(video.path);
  }

  Future<CaptureItem?> captureVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return null;
    return _createVideoItem(video.path);
  }

  Future<CaptureItem> _createVideoItem(String path) async {
    final item = CaptureItem(
      id: _uuid.v4(),
      filePath: path,
      type: CaptureType.video,
      isProcessed: true,
    );
    await _storage.saveItem(item);
    _items.insert(0, item);
    notifyListeners();
    return item;
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

  Future<CaptureItem> captureClipboard(String text) async {
    final item = CaptureItem(
      id: _uuid.v4(),
      rawText: text,
      type: CaptureType.clipboard,
      isProcessed: true,
    );

    item.category = _categorisation.categorise(text);
    item.extractedData = _categorisation.extractData(text);

    await _storage.saveItem(item);
    _items.insert(0, item);
    notifyListeners();
    return item;
  }

  Future<CaptureItem> captureNote(String text, {String? title}) async {
    final item = CaptureItem(
      id: _uuid.v4(),
      title: title,
      rawText: text,
      type: CaptureType.note,
      isProcessed: true,
    );

    item.category = _categorisation.categorise(text);
    item.extractedData = _categorisation.extractData(text);

    await _storage.saveItem(item);
    _items.insert(0, item);
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

    _processItem(item);
    return item;
  }

  // --- Processing ---

  Future<void> _processItem(CaptureItem item) async {
    if (item.isProcessed || item.filePath == null) return;

    // Skip OCR/labeling for videos - nothing to scan
    if (item.type == CaptureType.video) {
      item.isProcessed = true;
      await _storage.updateItem(item);
      notifyListeners();
      return;
    }

    try {
      // Run OCR and labeling in parallel
      final ocrFuture = _ocr.processImage(item.filePath!);
      final labelFuture = _labeling.labelImage(item.filePath!);

      final results = await Future.wait([ocrFuture, labelFuture]);
      final ocrResult = results[0] as OcrResult;
      final imageLabels = results[1] as List<String>;

      // Store labels
      item.labels = imageLabels;

      // Store OCR text and extract data
      if (ocrResult.isNotEmpty) {
        item.rawText = ocrResult.fullText;
        item.category = _categorisation.categorise(ocrResult.fullText);
        item.extractedData = _categorisation.extractData(ocrResult.fullText);
      }
    } catch (e) {
      debugPrint('Processing failed for ${item.id}: $e');
    }

    item.isProcessed = true;
    await _storage.updateItem(item);
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
    notifyListeners();
  }

  // --- Device Photo Import ---

  Future<bool> requestPhotoPermission() async {
    return _photoImport.requestPermission();
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
        _items = _storage.getAllItems();
        _isImporting = false;
        notifyListeners();
        _processUnprocessedItems();
      }
    }
  }

  void reloadItems() {
    _items = _storage.getAllItems();
    notifyListeners();
  }

  // --- Item Management ---

  Future<void> updateItem(CaptureItem item) async {
    await _storage.updateItem(item);
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) _items[idx] = item;
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final item = _items.firstWhere((i) => i.id == id);
    if (item.filePath != null) {
      try {
        await File(item.filePath!).delete();
      } catch (_) {}
    }
    await _storage.deleteItem(id);
    _items.removeWhere((i) => i.id == id);
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
    notifyListeners();
  }

  // --- Smart Collections ---

  List<SmartCollection> getSmartCollections() {
    final collections = <SmartCollection>[];
    final images = activeItems.where((i) => i.isImageType || i.type == CaptureType.video).toList();

    // Money - items with amounts
    final moneyItems = images.where((i) =>
        i.extractedData != null && i.extractedData!.containsKey('amounts')).toList();
    if (moneyItems.isNotEmpty) {
      collections.add(SmartCollection(
        key: 'money',
        name: 'Money',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF22C55E),
        count: moneyItems.length,
        coverPath: moneyItems.first.filePath,
      ));
    }

    // Contacts - items with phones or emails
    final contactItems = images.where((i) =>
        i.extractedData != null &&
        (i.extractedData!.containsKey('phones') || i.extractedData!.containsKey('emails'))).toList();
    if (contactItems.isNotEmpty) {
      collections.add(SmartCollection(
        key: 'contacts',
        name: 'Contacts',
        icon: Icons.person_rounded,
        color: const Color(0xFF3B82F6),
        count: contactItems.length,
        coverPath: contactItems.first.filePath,
      ));
    }

    // Links - items with URLs
    final linkItems = images.where((i) =>
        i.extractedData != null && i.extractedData!.containsKey('urls')).toList();
    if (linkItems.isNotEmpty) {
      collections.add(SmartCollection(
        key: 'links',
        name: 'Links',
        icon: Icons.link_rounded,
        color: const Color(0xFF8B5CF6),
        count: linkItems.length,
        coverPath: linkItems.first.filePath,
      ));
    }

    // Dates - items with dates
    final dateItems = images.where((i) =>
        i.extractedData != null && i.extractedData!.containsKey('dates')).toList();
    if (dateItems.isNotEmpty) {
      collections.add(SmartCollection(
        key: 'dates',
        name: 'Dates',
        icon: Icons.calendar_today_rounded,
        color: const Color(0xFFF59E0B),
        count: dateItems.length,
        coverPath: dateItems.first.filePath,
      ));
    }

    // Recipes - items with cooking keywords in rawText
    final recipeKeywords = ['ingredient', 'tbsp', 'tsp', 'cups', 'preheat', 'oven', 'bake', 'recipe', 'minutes', 'serves'];
    final recipeItems = images.where((i) {
      final text = i.rawText?.toLowerCase() ?? '';
      return recipeKeywords.where((k) => text.contains(k)).length >= 2;
    }).toList();
    if (recipeItems.isNotEmpty) {
      collections.add(SmartCollection(
        key: 'recipes',
        name: 'Recipes',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFEF4444),
        count: recipeItems.length,
        coverPath: recipeItems.first.filePath,
      ));
    }

    // Text Heavy - screenshots with lots of text (notes, articles)
    final textItems = images.where((i) {
      final text = i.rawText ?? '';
      return text.length > 200 && i.type == CaptureType.screenshot;
    }).toList();
    if (textItems.isNotEmpty) {
      collections.add(SmartCollection(
        key: 'text',
        name: 'Text & Notes',
        icon: Icons.article_rounded,
        color: const Color(0xFF06B6D4),
        count: textItems.length,
        coverPath: textItems.first.filePath,
      ));
    }

    return collections;
  }

  List<CaptureItem> getCollectionItems(String key) {
    final images = activeItems.where((i) => i.isImageType || i.type == CaptureType.video).toList();

    return switch (key) {
      'money' => images.where((i) =>
          i.extractedData != null && i.extractedData!.containsKey('amounts')).toList(),
      'contacts' => images.where((i) =>
          i.extractedData != null &&
          (i.extractedData!.containsKey('phones') || i.extractedData!.containsKey('emails'))).toList(),
      'links' => images.where((i) =>
          i.extractedData != null && i.extractedData!.containsKey('urls')).toList(),
      'dates' => images.where((i) =>
          i.extractedData != null && i.extractedData!.containsKey('dates')).toList(),
      'recipes' => images.where((i) {
          final text = i.rawText?.toLowerCase() ?? '';
          final keywords = ['ingredient', 'tbsp', 'tsp', 'cups', 'preheat', 'oven', 'bake', 'recipe', 'minutes', 'serves'];
          return keywords.where((k) => text.contains(k)).length >= 2;
        }).toList(),
      'text' => images.where((i) {
          final text = i.rawText ?? '';
          return text.length > 200 && i.type == CaptureType.screenshot;
        }).toList(),
      _ => [],
    };
  }

  // --- Document Scanner ---

  Future<void> captureScannedDocument({
    required String pdfPath,
    required String title,
    required int pageCount,
  }) async {
    final item = CaptureItem(
      id: _uuid.v4(),
      title: title,
      filePath: pdfPath,
      type: CaptureType.document,
      category: ItemCategory.document,
      isProcessed: true,
    );

    await _storage.saveItem(item);
    _items.insert(0, item);
    notifyListeners();
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    _ocr.dispose();
    _labeling.dispose();
    super.dispose();
  }
}

class SmartCollection {
  final String key;
  final String name;
  final IconData icon;
  final Color color;
  final int count;
  final String? coverPath;

  SmartCollection({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
    this.coverPath,
  });
}
