import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/barcode_service.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  final ImagePicker _picker = ImagePicker();
  final List<_ScanResult> _results = [];
  bool _isScanning = false;

  @override
  void dispose() {
    _barcodeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MijigiColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 60)),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'QR & Barcodes',
                    style: TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: MijigiColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings_rounded,
                          color: MijigiColors.textTertiary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Scan buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ScanButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Scan with Camera',
                      gradient: MijigiGradients.buttonGradient,
                      onTap: _isScanning ? null : _scanFromCamera,
                      isLoading: _isScanning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScanButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Scan from Photo',
                      gradient: MijigiGradients.cardElevatedGradient,
                      onTap: _isScanning ? null : _scanFromGallery,
                      border: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Supported formats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FormatBadge('QR Code'),
                  _FormatBadge('EAN-13'),
                  _FormatBadge('UPC'),
                  _FormatBadge('Code-128'),
                  _FormatBadge('Data Matrix'),
                  _FormatBadge('PDF417'),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Results
          if (_results.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty())
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Results',
                      style: TextStyle(
                        color: MijigiColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _results.clear()),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: MijigiColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _results[index],
                    );
                  },
                  childCount: _results.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner_rounded,
                size: 56,
                color: MijigiColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('Scan a QR code or barcode',
                style: TextStyle(
                    color: MijigiColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(
              'Take a photo or pick one from your gallery',
              style: TextStyle(
                  color: MijigiColors.textTertiary.withValues(alpha: 0.7),
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (photo != null) _processImage(photo.path);
  }

  Future<void> _scanFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (photo != null) _processImage(photo.path);
  }

  Future<void> _processImage(String path) async {
    setState(() => _isScanning = true);

    final barcodes = await _barcodeService.scanImage(path);

    if (barcodes.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No QR code or barcode found',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    for (final barcode in barcodes) {
      _results.insert(
        0,
        _ScanResult(
          barcode: barcode,
          imagePath: path,
          onCopy: () => _copy(barcode.rawValue),
          onAction: () => _launchAction(barcode),
        ),
      );
    }

    setState(() => _isScanning = false);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text',
            style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _launchAction(ScannedBarcode barcode) async {
    Uri? uri;

    if (barcode.structuredData?['url'] != null) {
      uri = Uri.tryParse(barcode.structuredData!['url']!);
    } else if (barcode.structuredData?['number'] != null) {
      uri = Uri(scheme: 'tel', path: barcode.structuredData!['number']);
    } else if (barcode.structuredData?['address'] != null) {
      uri = Uri(scheme: 'mailto', path: barcode.structuredData!['address']);
    } else if (barcode.rawValue.startsWith('http')) {
      uri = Uri.tryParse(barcode.rawValue);
    }

    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}

// --- Scan button ---
class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool border;

  const _ScanButton({
    required this.icon,
    required this.label,
    required this.gradient,
    this.onTap,
    this.isLoading = false,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: border
              ? Border.all(
                  color: MijigiColors.border.withValues(alpha: 0.5),
                  width: 0.5)
              : null,
          boxShadow: !border
              ? [
                  BoxShadow(
                    color: MijigiColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon,
                  color: border
                      ? MijigiColors.textSecondary
                      : Colors.white,
                  size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: border ? MijigiColors.textSecondary : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Format badge ---
class _FormatBadge extends StatelessWidget {
  final String label;
  const _FormatBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: MijigiColors.textTertiary.withValues(alpha: 0.7),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// --- Scan result card ---
class _ScanResult extends StatelessWidget {
  final ScannedBarcode barcode;
  final String imagePath;
  final VoidCallback onCopy;
  final VoidCallback onAction;

  const _ScanResult({
    required this.barcode,
    required this.imagePath,
    required this.onCopy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = barcode.structuredData != null &&
        (barcode.structuredData!.containsKey('url') ||
            barcode.structuredData!.containsKey('number') ||
            barcode.structuredData!.containsKey('address') ||
            barcode.rawValue.startsWith('http'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: MijigiGradients.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MijigiColors.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + thumbnail
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon, size: 12, color: _typeColor),
                    const SizedBox(width: 4),
                    Text(
                      barcode.typeLabel,
                      style: TextStyle(
                        color: _typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Small thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(imagePath),
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Main value
          Text(
            barcode.displayValue,
            style: const TextStyle(
              color: MijigiColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Structured data
          if (barcode.structuredData != null &&
              barcode.structuredData!.length > 1) ...[
            const SizedBox(height: 8),
            ...barcode.structuredData!.entries
                .where((e) => e.value.isNotEmpty)
                .take(4)
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Text(
                            '${e.key}: ',
                            style: TextStyle(
                              color: MijigiColors.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                color: MijigiColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
          ],

          const SizedBox(height: 10),

          // Action buttons
          Row(
            children: [
              _ActionBtn(
                icon: Icons.content_copy_rounded,
                label: 'Copy',
                color: MijigiColors.textSecondary,
                onTap: onCopy,
              ),
              if (hasAction) ...[
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: _actionIcon,
                  label: _actionLabel,
                  color: _typeColor,
                  onTap: onAction,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color get _typeColor => switch (barcode.typeLabel) {
    'URL' => const Color(0xFF3B82F6),
    'WiFi' => const Color(0xFF22C55E),
    'Email' => const Color(0xFF8B5CF6),
    'Phone' => const Color(0xFF06B6D4),
    'Contact' => const Color(0xFFF59E0B),
    'Event' => const Color(0xFFEF4444),
    'Location' => const Color(0xFFF97316),
    'Product' => const Color(0xFFEC4899),
    _ => MijigiColors.primary,
  };

  IconData get _typeIcon => switch (barcode.typeLabel) {
    'URL' => Icons.link_rounded,
    'WiFi' => Icons.wifi_rounded,
    'Email' => Icons.email_rounded,
    'Phone' => Icons.phone_rounded,
    'Contact' => Icons.person_rounded,
    'Event' => Icons.event_rounded,
    'Location' => Icons.location_on_rounded,
    'Product' => Icons.shopping_bag_rounded,
    'ISBN' => Icons.menu_book_rounded,
    _ => Icons.qr_code_rounded,
  };

  IconData get _actionIcon => switch (barcode.typeLabel) {
    'URL' => Icons.open_in_new_rounded,
    'Email' => Icons.send_rounded,
    'Phone' => Icons.call_rounded,
    _ => Icons.open_in_new_rounded,
  };

  String get _actionLabel => switch (barcode.typeLabel) {
    'URL' => 'Open',
    'Email' => 'Send',
    'Phone' => 'Call',
    _ => 'Open',
  };
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
