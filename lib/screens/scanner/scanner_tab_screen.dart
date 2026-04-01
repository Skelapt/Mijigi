import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import 'scanner_review_screen.dart';
import '../item_detail/item_detail_screen.dart';

class ScannerTabScreen extends StatefulWidget {
  const ScannerTabScreen({super.key});

  @override
  State<ScannerTabScreen> createState() => _ScannerTabScreenState();
}

class _ScannerTabScreenState extends State<ScannerTabScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  Future<void> _captureDocument() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 100,
      );

      if (image != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ScannerReviewScreen(initialImagePath: image.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open camera: $e'),
            backgroundColor: MijigiColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  List<CaptureItem> _getRecentScans(AppProvider provider) {
    return provider.activeItems
        .where((item) =>
            item.type == CaptureType.document &&
            item.filePath != null &&
            item.filePath!.endsWith('.pdf'))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _estimatePageCount(CaptureItem item) {
    if (item.extractedData != null &&
        item.extractedData!.containsKey('pageCount')) {
      return item.extractedData!['pageCount'] as int;
    }
    // Default estimate
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final recentScans = _getRecentScans(provider);

        return Scaffold(
          backgroundColor: MijigiColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Scan viewfinder area
                SliverToBoxAdapter(
                  child: _buildScanArea(),
                ),

                // Feature badges
                SliverToBoxAdapter(
                  child: _buildFeatureBadges(),
                ),

                // Recent scans header
                if (recentScans.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            color: MijigiColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Scans',
                            style: TextStyle(
                              color: MijigiColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${recentScans.length} document${recentScans.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: MijigiColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Recent scans list
                if (recentScans.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildScanItem(recentScans[index]),
                      childCount: recentScans.length,
                    ),
                  ),

                // Empty state
                if (recentScans.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: MijigiColors.textTertiary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No scanned documents yet',
                            style: TextStyle(
                              color: MijigiColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the scan button above to get started',
                            style: TextStyle(
                              color: MijigiColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 320,
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MijigiColors.border,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Background grid pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
          ),

          // Corner markers
          ..._buildCornerMarkers(),

          // Center scan button
          Center(
            child: GestureDetector(
              onTap: _isCapturing ? null : _captureDocument,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCapturing
                      ? MijigiColors.primary.withValues(alpha:0.3)
                      : MijigiColors.primary.withValues(alpha:0.15),
                  border: Border.all(
                    color: MijigiColors.primary,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MijigiColors.primary.withValues(alpha:0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCapturing
                          ? Icons.hourglass_top_rounded
                          : Icons.camera_alt_rounded,
                      color: MijigiColors.primaryLight,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isCapturing ? 'Opening...' : 'Tap to Scan',
                      style: const TextStyle(
                        color: MijigiColors.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top label
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: MijigiColors.surfaceLight.withValues(alpha:0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: MijigiColors.border,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MijigiColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: MijigiColors.primary.withValues(alpha:0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PDF Scanner',
                      style: TextStyle(
                        color: MijigiColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    const cornerSize = 28.0;
    const cornerThickness = 3.0;
    const cornerColor = MijigiColors.primary;
    const inset = 24.0;

    Widget buildCorner({
      required AlignmentGeometry alignment,
      required BorderRadius borderRadius,
    }) {
      return Positioned(
        top: alignment == Alignment.topLeft || alignment == Alignment.topRight
            ? inset
            : null,
        bottom:
            alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? inset
                : null,
        left:
            alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? inset
                : null,
        right:
            alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? inset
                : null,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border(
              top: alignment == Alignment.topLeft ||
                      alignment == Alignment.topRight
                  ? const BorderSide(
                      color: cornerColor, width: cornerThickness)
                  : BorderSide.none,
              bottom: alignment == Alignment.bottomLeft ||
                      alignment == Alignment.bottomRight
                  ? const BorderSide(
                      color: cornerColor, width: cornerThickness)
                  : BorderSide.none,
              left: alignment == Alignment.topLeft ||
                      alignment == Alignment.bottomLeft
                  ? const BorderSide(
                      color: cornerColor, width: cornerThickness)
                  : BorderSide.none,
              right: alignment == Alignment.topRight ||
                      alignment == Alignment.bottomRight
                  ? const BorderSide(
                      color: cornerColor, width: cornerThickness)
                  : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      buildCorner(
        alignment: Alignment.topLeft,
        borderRadius:
            const BorderRadius.only(topLeft: Radius.circular(4)),
      ),
      buildCorner(
        alignment: Alignment.topRight,
        borderRadius:
            const BorderRadius.only(topRight: Radius.circular(4)),
      ),
      buildCorner(
        alignment: Alignment.bottomLeft,
        borderRadius:
            const BorderRadius.only(bottomLeft: Radius.circular(4)),
      ),
      buildCorner(
        alignment: Alignment.bottomRight,
        borderRadius:
            const BorderRadius.only(bottomRight: Radius.circular(4)),
      ),
    ];
  }

  Widget _buildFeatureBadges() {
    final features = [
      _FeatureBadge(icon: Icons.layers_rounded, label: 'Multi-Page'),
      _FeatureBadge(icon: Icons.tune_rounded, label: 'Filters'),
      _FeatureBadge(icon: Icons.rotate_right_rounded, label: 'Rotate'),
      _FeatureBadge(icon: Icons.picture_as_pdf_rounded, label: 'PDF Export'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: features,
      ),
    );
  }

  Widget _buildScanItem(CaptureItem item) {
    final pageCount = _estimatePageCount(item);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(itemId: item.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MijigiColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: MijigiColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // PDF icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: MijigiColors.filePdf.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: MijigiColors.filePdf,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Title and meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayTitle,
                        style: const TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDate(item.createdAt),
                            style: const TextStyle(
                              color: MijigiColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: MijigiColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$pageCount page${pageCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: MijigiColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: MijigiColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MijigiColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MijigiColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MijigiColors.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: MijigiColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MijigiColors.border.withValues(alpha:0.3)
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
