import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class ScannedBarcode {
  final String rawValue;
  final String displayValue;
  final String typeLabel;
  final Map<String, String>? structuredData;

  ScannedBarcode({
    required this.rawValue,
    required this.displayValue,
    required this.typeLabel,
    this.structuredData,
  });
}

class BarcodeService {
  BarcodeScanner? _scanner;

  BarcodeScanner get scanner {
    _scanner ??= BarcodeScanner(formats: [BarcodeFormat.all]);
    return _scanner!;
  }

  /// Scan an image file for barcodes/QR codes
  Future<List<ScannedBarcode>> scanImage(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final barcodes = await scanner.processImage(inputImage);

      return barcodes.map((barcode) {
        final structured = <String, String>{};
        String typeLabel = 'Code';
        final barcodeValue = barcode.value;

        switch (barcode.type) {
          case BarcodeType.url:
            typeLabel = 'URL';
            if (barcodeValue is BarcodeUrl) {
              structured['url'] = barcodeValue.url ?? barcode.rawValue ?? '';
            }
            break;
          case BarcodeType.wifi:
            typeLabel = 'WiFi';
            if (barcodeValue is BarcodeWifi) {
              structured['ssid'] = barcodeValue.ssid ?? '';
              structured['password'] = barcodeValue.password ?? '';
            }
            break;
          case BarcodeType.email:
            typeLabel = 'Email';
            if (barcodeValue is BarcodeEmail) {
              structured['address'] = barcodeValue.address ?? '';
              structured['subject'] = barcodeValue.subject ?? '';
              structured['body'] = barcodeValue.body ?? '';
            }
            break;
          case BarcodeType.phone:
            typeLabel = 'Phone';
            if (barcodeValue is BarcodePhone) {
              structured['number'] = barcodeValue.number ?? '';
            }
            break;
          case BarcodeType.sms:
            typeLabel = 'SMS';
            if (barcodeValue is BarcodeSMS) {
              structured['number'] = barcodeValue.phoneNumber ?? '';
              structured['message'] = barcodeValue.message ?? '';
            }
            break;
          case BarcodeType.contactInfo:
            typeLabel = 'Contact';
            if (barcodeValue is BarcodeContactInfo) {
              if (barcodeValue.formattedName != null) {
                structured['name'] = barcodeValue.formattedName!;
              }
              if (barcodeValue.phoneNumbers.isNotEmpty) {
                structured['phone'] = barcodeValue.phoneNumbers.first.number ?? '';
              }
              if (barcodeValue.emails.isNotEmpty) {
                structured['email'] = barcodeValue.emails.first.address ?? '';
              }
            }
            break;
          case BarcodeType.calendarEvent:
            typeLabel = 'Event';
            if (barcodeValue is BarcodeCalenderEvent) {
              structured['summary'] = barcodeValue.summary ?? '';
              structured['location'] = barcodeValue.location ?? '';
            }
            break;
          case BarcodeType.geoCoordinates:
            typeLabel = 'Location';
            if (barcodeValue is BarcodeGeoPoint) {
              structured['lat'] = (barcodeValue.latitude ?? 0).toString();
              structured['lng'] = (barcodeValue.longitude ?? 0).toString();
            }
            break;
          case BarcodeType.product:
            typeLabel = 'Product';
            break;
          case BarcodeType.isbn:
            typeLabel = 'ISBN';
            break;
          default:
            typeLabel = 'Code';
        }

        return ScannedBarcode(
          rawValue: barcode.rawValue ?? '',
          displayValue: barcode.displayValue ?? barcode.rawValue ?? '',
          typeLabel: typeLabel,
          structuredData: structured.isNotEmpty ? structured : null,
        );
      }).toList();
    } catch (e, stack) {
      debugPrint('[Picxtract] Barcode scan failed: $e');
      debugPrint('[Picxtract] Stack: $stack');
      return [];
    }
  }

  void dispose() {
    _scanner?.close();
  }
}
