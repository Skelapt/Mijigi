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

/// A device photo that hasn't been fully imported yet.
/// Shows instantly from device thumbnail.
class DevicePhoto {
  final AssetEntity asset;
  final String id;
  Uint8List? thumbnail;

  DevicePhoto({required this.asset, required this.id});
}

class DevicePhotosService {
  final _uuid = const Uuid();

  /// Request permission
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result == PermissionState.limited;
  }

  /// Load device photos INSTANTLY - just metadata + thumbnails, no copying
  Future<List<DevicePhoto>> loadDevicePhotos({int limit = 500}) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (albums.isEmpty) return [];

    final photos = <DevicePhoto>[];
    for (final album in albums) {
      final assets = await album.getAssetListPaged(page: 0, size: limit);
      for (final asset in assets) {
        final assetId = 'asset_${asset.id}_${asset.createDateTime.millisecondsSinceEpoch}';
        photos.add(DevicePhoto(asset: asset, id: assetId));
      }
      if (photos.length >= limit) break;
    }

    return photos.take(limit).toList();
  }

  /// Load thumbnail for a single device photo
  Future<Uint8List?> loadThumbnail(AssetEntity asset) async {
    try {
      return await asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
        quality: 80,
      );
    } catch (_) {
      return null;
    }
  }

  /// Background process: copy file, run OCR + labeling, save to storage
  /// Returns the CaptureItem when done
  Future<CaptureItem?> processInBackground({
    required AssetEntity asset,
    required String assetKey,
    required StorageService storage,
    required OcrService ocr,
    required LabelingService labeling,
    required CategorisationService categorisation,
  }) async {
    // Already processed?
    final existing = storage.getItem(assetKey);
    if (existing != null) return existing;

    try {
      final file = await asset.file;
      if (file == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/picxtract_photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      // Copy file
      final ext = file.path.split('.').last;
      final newPath = '${photosDir.path}/${_uuid.v4()}.$ext';
      await file.copy(newPath);

      // Determine type
      final isScreenshot = _isScreenshot(asset);
      final type = isScreenshot ? CaptureType.screenshot : CaptureType.photo;

      final item = CaptureItem(
        id: assetKey,
        filePath: newPath,
        type: type,
        createdAt: asset.createDateTime,
        isProcessed: false,
      );

      // Run OCR + labeling in parallel
      try {
        final results = await Future.wait([
          ocr.processImage(newPath),
          labeling.labelImage(newPath),
        ]);
        final ocrResult = results[0] as OcrResult;
        final labels = results[1] as List<String>;

        item.labels = labels;

        if (ocrResult.isNotEmpty) {
          item.rawText = ocrResult.fullText;
          item.category = categorisation.categorise(ocrResult.fullText);
          item.extractedData = categorisation.extractData(ocrResult.fullText);
        }
      } catch (e) {
        debugPrint('[Picxtract] Processing failed: $e');
      }

      item.isProcessed = true;
      await storage.saveItem(item);
      return item;
    } catch (e) {
      debugPrint('[Picxtract] Background import failed: $e');
      return null;
    }
  }

  bool _isScreenshot(AssetEntity asset) {
    final width = asset.width;
    final height = asset.height;
    if (width == 0 || height == 0) return false;
    final ratio = width > height ? width / height : height / width;
    return ratio > 1.7 && ratio < 2.5;
  }
}
