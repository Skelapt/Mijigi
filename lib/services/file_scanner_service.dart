import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart' as mime_lib;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/capture_item.dart';
import 'storage_service.dart';
import 'pdf_service.dart';
import 'categorisation_service.dart';
import 'extraction_service.dart';

/// Scanned file metadata.
class ScannedFile {
  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime modified;
  final String? mimeType;
  final String? hash; // for duplicate detection

  ScannedFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.modified,
    this.mimeType,
    this.hash,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  bool get isPdf => extension.toLowerCase() == '.pdf';
  bool get isImage => ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic']
      .contains(extension.toLowerCase());
  bool get isDocument => ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt', '.xls', '.xlsx', '.csv']
      .contains(extension.toLowerCase());
  bool get isAudio => ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac']
      .contains(extension.toLowerCase());
  bool get isVideo => ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp']
      .contains(extension.toLowerCase());
  bool get isTextReadable => ['.txt', '.csv', '.json', '.xml', '.html', '.md', '.log']
      .contains(extension.toLowerCase());
}

/// Duplicate file group.
class DuplicateGroup {
  final String hash;
  final int fileSize;
  final List<ScannedFile> files;

  DuplicateGroup({
    required this.hash,
    required this.fileSize,
    required this.files,
  });

  int get wastedBytes => fileSize * (files.length - 1);
}

/// Storage breakdown by file type.
class StorageBreakdown {
  final int totalFiles;
  final int totalBytes;
  final Map<String, int> byExtension; // extension -> bytes
  final Map<String, int> countByExtension; // extension -> count
  final int documentCount;
  final int imageCount;
  final int audioCount;
  final int videoCount;
  final int otherCount;
  final int duplicateCount;
  final int duplicateWastedBytes;

  StorageBreakdown({
    required this.totalFiles,
    required this.totalBytes,
    required this.byExtension,
    required this.countByExtension,
    required this.documentCount,
    required this.imageCount,
    required this.audioCount,
    required this.videoCount,
    required this.otherCount,
    this.duplicateCount = 0,
    this.duplicateWastedBytes = 0,
  });

  String get totalSizeFormatted {
    if (totalBytes < 1024) return '${totalBytes}B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)}KB';
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// File scan progress.
class FileScanProgress {
  final int totalFound;
  final int processed;
  final int imported;
  final String currentFile;
  final FileScanStatus status;

  FileScanProgress({
    required this.totalFound,
    required this.processed,
    required this.imported,
    required this.currentFile,
    required this.status,
  });

  double get progress => totalFound > 0 ? processed / totalFound : 0;
}

enum FileScanStatus { scanning, processing, complete, error }

/// Scans device file system and imports files into Mijigi.
class FileScannerService {
  final PdfService _pdfService = PdfService();
  final CategorisationService _categorisation = CategorisationService();
  final ExtractionService _extraction = ExtractionService();
  final _uuid = const Uuid();

  /// Common directories to scan on Android.
  static const _androidScanPaths = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/storage/emulated/0/Documents',
    '/storage/emulated/0/DCIM',
    '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
    '/storage/emulated/0/Telegram/Telegram Documents',
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
  ];

  /// File extensions we care about.
  static const _targetExtensions = {
    '.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt',
    '.xls', '.xlsx', '.csv',
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic',
    '.mp3', '.wav', '.m4a', '.aac',
    '.mp4', '.mov', '.avi', '.mkv',
    '.json', '.xml', '.html', '.md',
  };

  /// Request file system permission.
  Future<bool> requestPermission() async {
    // Try manage external storage first (Android 11+)
    var status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return true;

    status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    // Fallback to regular storage permission
    status = await Permission.storage.status;
    if (status.isGranted) return true;

    status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Scan device for files and return all found files.
  Future<List<ScannedFile>> scanDeviceFiles() async {
    final files = <ScannedFile>[];

    // Get app-specific directories too
    final appDir = await getApplicationDocumentsDirectory();
    final scanPaths = [..._androidScanPaths, appDir.path];

    for (final path in scanPaths) {
      final dir = Directory(path);
      if (!await dir.exists()) continue;

      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;

          final name = entity.path.split('/').last;
          if (name.startsWith('.')) continue; // Skip hidden files

          final ext = name.contains('.')
              ? '.${name.split('.').last}'.toLowerCase()
              : '';

          if (!_targetExtensions.contains(ext)) continue;

          try {
            final stat = await entity.stat();
            final mimeType = mime_lib.lookupMimeType(entity.path);

            files.add(ScannedFile(
              path: entity.path,
              name: name,
              extension: ext,
              sizeBytes: stat.size,
              modified: stat.modified,
              mimeType: mimeType,
            ));
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Error scanning $path: $e');
      }
    }

    // Sort by modified date, newest first
    files.sort((a, b) => b.modified.compareTo(a.modified));
    return files;
  }

  /// Import scanned files into Mijigi as CaptureItems.
  Stream<FileScanProgress> importFiles({
    required StorageService storage,
    required Set<String> existingFilePaths,
  }) async* {
    yield FileScanProgress(
      totalFound: 0,
      processed: 0,
      imported: 0,
      currentFile: 'Scanning device...',
      status: FileScanStatus.scanning,
    );

    final files = await scanDeviceFiles();
    // Filter out already imported
    final newFiles = files.where((f) => !existingFilePaths.contains(f.path)).toList();

    int processed = 0;
    int imported = 0;

    for (final file in newFiles) {
      processed++;

      yield FileScanProgress(
        totalFound: newFiles.length,
        processed: processed,
        imported: imported,
        currentFile: file.name,
        status: FileScanStatus.processing,
      );

      try {
        final item = await _processFile(file);
        if (item != null) {
          await storage.saveItem(item);
          imported++;
        }
      } catch (e) {
        debugPrint('Error processing ${file.name}: $e');
      }
    }

    yield FileScanProgress(
      totalFound: newFiles.length,
      processed: processed,
      imported: imported,
      currentFile: '',
      status: FileScanStatus.complete,
    );
  }

  /// Process a single file into a CaptureItem.
  Future<CaptureItem?> _processFile(ScannedFile file) async {
    String? extractedText;

    // Extract text based on file type
    if (file.isPdf) {
      extractedText = await _pdfService.extractText(file.path);
    } else if (file.isTextReadable) {
      try {
        extractedText = await File(file.path).readAsString();
        // Limit to prevent huge files
        if (extractedText.length > 50000) {
          extractedText = extractedText.substring(0, 50000);
        }
      } catch (_) {}
    }
    // Images will be OCR'd by the existing pipeline

    final captureType = file.isImage
        ? CaptureType.photo
        : CaptureType.document;

    final item = CaptureItem(
      id: _uuid.v4(),
      title: file.name,
      filePath: file.path,
      rawText: extractedText,
      type: captureType,
      isProcessed: extractedText != null && extractedText.isNotEmpty,
    );

    // Categorise and extract intelligence from text
    if (extractedText != null && extractedText.isNotEmpty) {
      item.category = _categorisation.categorise(extractedText);
      final extraction = _extraction.extract(extractedText);
      item.extractedData = extraction.toMap();
    }

    return item;
  }

  /// Detect duplicate files by size + partial hash.
  Future<List<DuplicateGroup>> findDuplicates(List<ScannedFile> files) async {
    // Group by size first (fast filter)
    final sizeGroups = <int, List<ScannedFile>>{};
    for (final file in files) {
      sizeGroups.putIfAbsent(file.sizeBytes, () => []).add(file);
    }

    final duplicates = <DuplicateGroup>[];

    for (final entry in sizeGroups.entries) {
      if (entry.value.length < 2) continue;

      // Hash files with same size
      final hashGroups = <String, List<ScannedFile>>{};
      for (final file in entry.value) {
        try {
          final hash = await _fileHash(file.path);
          hashGroups.putIfAbsent(hash, () => []).add(file);
        } catch (_) {}
      }

      for (final hashEntry in hashGroups.entries) {
        if (hashEntry.value.length >= 2) {
          duplicates.add(DuplicateGroup(
            hash: hashEntry.key,
            fileSize: entry.key,
            files: hashEntry.value,
          ));
        }
      }
    }

    duplicates.sort((a, b) => b.wastedBytes.compareTo(a.wastedBytes));
    return duplicates;
  }

  /// Get storage breakdown.
  StorageBreakdown analyzeStorage(List<ScannedFile> files) {
    final byExtension = <String, int>{};
    final countByExtension = <String, int>{};
    int totalBytes = 0;
    int documents = 0, images = 0, audio = 0, video = 0, other = 0;

    for (final file in files) {
      totalBytes += file.sizeBytes;
      byExtension[file.extension] =
          (byExtension[file.extension] ?? 0) + file.sizeBytes;
      countByExtension[file.extension] =
          (countByExtension[file.extension] ?? 0) + 1;

      if (file.isDocument) {
        documents++;
      } else if (file.isImage) {
        images++;
      } else if (file.isAudio) {
        audio++;
      } else if (file.isVideo) {
        video++;
      } else {
        other++;
      }
    }

    return StorageBreakdown(
      totalFiles: files.length,
      totalBytes: totalBytes,
      byExtension: byExtension,
      countByExtension: countByExtension,
      documentCount: documents,
      imageCount: images,
      audioCount: audio,
      videoCount: video,
      otherCount: other,
    );
  }

  /// Compute a quick hash of a file (first 8KB + last 8KB).
  Future<String> _fileHash(String path) async {
    final file = File(path);
    final length = await file.length();
    final raf = await file.open();

    try {
      List<int> bytes;
      if (length <= 16384) {
        bytes = await raf.read(length);
      } else {
        final head = await raf.read(8192);
        await raf.setPosition(length - 8192);
        final tail = await raf.read(8192);
        bytes = [...head, ...tail];
      }
      return md5.convert(bytes).toString();
    } finally {
      await raf.close();
    }
  }
}
