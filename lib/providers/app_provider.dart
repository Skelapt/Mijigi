import 'dart:io';
import 'package:flutter/foundation.dart';
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

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storage.init();
    _items = _storage.getAllItems();

    _isLoading = false;
    notifyListeners();

    _processUnprocessedItems();
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

  @override
  void dispose() {
    _ocr.dispose();
    _labeling.dispose();
    super.dispose();
  }
}
