import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/capture_item.dart';
import 'ocr_service.dart';
import 'labeling_service.dart';
import 'categorisation_service.dart';
import 'storage_service.dart';

class PhotoImportService {
  final OcrService _ocr = OcrService();
  final LabelingService _labeling = LabelingService();
  final CategorisationService _categorisation = CategorisationService();
  final _uuid = const Uuid();

  /// Request permission to access photos
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result == PermissionState.limited;
  }

  /// Get total photo count on device
  Future<int> getDevicePhotoCount() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    int total = 0;
    for (final album in albums) {
      total += await album.assetCountAsync;
    }
    return total;
  }

  /// Scan device photos and import new ones
  /// Returns a stream of progress updates
  Stream<ImportProgress> importDevicePhotos({
    required StorageService storage,
    required Set<String> existingFilePaths,
    int batchSize = 20,
  }) async* {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common, // images + videos
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (albums.isEmpty) {
      yield ImportProgress(
        total: 0,
        processed: 0,
        imported: 0,
        status: ImportStatus.complete,
        message: 'No photos found on device',
      );
      return;
    }

    // Get all assets from all albums
    int totalAssets = 0;
    for (final album in albums) {
      totalAssets += await album.assetCountAsync;
    }

    yield ImportProgress(
      total: totalAssets,
      processed: 0,
      imported: 0,
      status: ImportStatus.scanning,
      message: 'Found $totalAssets items. Scanning...',
    );

    final appDir = await getApplicationDocumentsDirectory();
    final mijigiDir = Directory('${appDir.path}/mijigi_photos');
    if (!await mijigiDir.exists()) {
      await mijigiDir.create(recursive: true);
    }

    int processed = 0;
    int imported = 0;
    int skipped = 0;

    for (final album in albums) {
      final assetCount = await album.assetCountAsync;
      int page = 0;

      while (page * batchSize < assetCount) {
        final assets = await album.getAssetListPaged(
          page: page,
          size: batchSize,
        );

        for (final asset in assets) {
          processed++;

          // Skip if already imported (check by original file name + date)
          final assetId = '${asset.id}_${asset.createDateTime.millisecondsSinceEpoch}';
          final existingKey = 'asset_$assetId';

          // Check if we already have this asset
          final existing = storage.getItem(existingKey);
          if (existing != null) {
            skipped++;
            continue;
          }

          try {
            // Get the file
            final file = await asset.file;
            if (file == null) continue;

            // Copy to app directory for persistence
            final ext = file.path.split('.').last;
            final newPath = '${mijigiDir.path}/${_uuid.v4()}.$ext';
            await file.copy(newPath);

            // Determine type
            final isVideo = asset.type == AssetType.video;
            final CaptureType type;
            if (isVideo) {
              type = CaptureType.video;
            } else if (_isScreenshot(asset)) {
              type = CaptureType.screenshot;
            } else {
              type = CaptureType.photo;
            }

            // Generate thumbnail for videos
            String? thumbnailPath;
            if (isVideo) {
              try {
                final thumbData = await asset.thumbnailDataWithSize(
                  const ThumbnailSize(300, 300),
                );
                if (thumbData != null) {
                  thumbnailPath = '${mijigiDir.path}/thumb_${_uuid.v4()}.jpg';
                  await File(thumbnailPath).writeAsBytes(thumbData);
                }
              } catch (e) {
                debugPrint('Thumbnail generation failed: $e');
              }
            }

            // Create capture item
            final item = CaptureItem(
              id: existingKey,
              filePath: newPath,
              thumbnailPath: thumbnailPath,
              type: type,
              createdAt: asset.createDateTime,
              isProcessed: isVideo, // videos don't need OCR processing
            );

            // Run OCR + image labeling for images (not videos)
            if (!isVideo) {
              try {
                // Run both in parallel for speed
                final results = await Future.wait([
                  _ocr.processImage(newPath),
                  _labeling.labelImage(newPath),
                ]);
                final ocrResult = results[0] as OcrResult;
                final labels = results[1] as List<String>;

                // Store labels for visual search
                item.labels = labels;

                if (ocrResult.isNotEmpty) {
                  item.rawText = ocrResult.fullText;
                  item.category = _categorisation.categorise(ocrResult.fullText);
                  item.extractedData =
                      _categorisation.extractData(ocrResult.fullText);
                }
              } catch (e) {
                debugPrint('Processing failed for asset: $e');
              }
              item.isProcessed = true;
            }
            await storage.saveItem(item);
            imported++;
          } catch (e) {
            debugPrint('Failed to import asset: $e');
          }

          // Yield progress every 5 items
          if (processed % 5 == 0 || processed == totalAssets) {
            yield ImportProgress(
              total: totalAssets,
              processed: processed,
              imported: imported,
              skipped: skipped,
              status: ImportStatus.importing,
              message:
                  'Processing $processed/$totalAssets • $imported new items',
            );
          }
        }

        page++;
      }
    }

    yield ImportProgress(
      total: totalAssets,
      processed: processed,
      imported: imported,
      skipped: skipped,
      status: ImportStatus.complete,
      message: imported > 0
          ? 'Done! Imported $imported new items from $totalAssets photos.'
          : 'All items already imported. $totalAssets items indexed.',
    );
  }

  bool _isScreenshot(AssetEntity asset) {
    // Heuristic: screenshots are usually exact screen dimensions
    // and are in a Screenshots folder
    final title = (asset.title ?? '').toLowerCase();
    if (title.contains('screenshot') || title.contains('screen_shot')) {
      return true;
    }

    // Common screenshot dimensions (width x height)
    final w = asset.width;
    final h = asset.height;
    if (w > 0 && h > 0) {
      final ratio = w > h ? w / h : h / w;
      // Screenshots tend to have phone-like aspect ratios
      // and standard resolutions
      if (ratio > 1.7 && ratio < 2.3) {
        if (w >= 1080 || h >= 1080) {
          return title.isEmpty; // Photos usually have camera-generated names
        }
      }
    }

    return false;
  }

  void dispose() {
    _ocr.dispose();
  }
}

class ImportProgress {
  final int total;
  final int processed;
  final int imported;
  final int skipped;
  final ImportStatus status;
  final String message;

  ImportProgress({
    required this.total,
    required this.processed,
    required this.imported,
    this.skipped = 0,
    required this.status,
    required this.message,
  });

  double get progress =>
      total > 0 ? processed / total : 0;
}

enum ImportStatus {
  scanning,
  importing,
  complete,
  error,
}
