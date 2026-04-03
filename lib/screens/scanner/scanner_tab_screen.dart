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

class _ScannerTabScreenState extends State<ScannerTabScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
            child: Column(
              children: [
                // Scan viewfinder area - takes most of the screen
                Expanded(
                  flex: 3,
                  child: _buildScanArea(),
                ),

                // Recent scans - small section at bottom
                if (recentScans.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: MijigiColors.textTertiary.withValues(alpha: 0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recent Scans',
                                style: TextStyle(
                                  color: MijigiColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${recentScans.length}',
                                style: TextStyle(
                                  color: MijigiColors.textTertiary.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: recentScans.length,
                            itemBuilder: (context, index) =>
                                _buildScanItem(recentScans[index]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Empty state when no scans
                if (recentScans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Text(
                      'No scanned documents yet',
                      style: TextStyle(
                        color: MijigiColors.textTertiary.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
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
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C1018),
            Color(0xFF080C12),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: MijigiColors.border.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          // Background grid pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
          ),

          // Corner markers with glow
          ..._buildCornerMarkers(),

          // Center scan button
          Center(
            child: GestureDetector(
              onTap: _isCapturing ? null : _captureDocument,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseValue = _pulseController.value;
                  return Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCapturing
                          ? MijigiColors.primary.withValues(alpha: 0.2)
                          : MijigiColors.primary.withValues(alpha: 0.06 + pulseValue * 0.06),
                      border: Border.all(
                        color: MijigiColors.primary.withValues(alpha: 0.5 + pulseValue * 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MijigiColors.primary.withValues(alpha: 0.1 + pulseValue * 0.1),
                          blurRadius: 30 + pulseValue * 10,
                          spreadRadius: pulseValue * 3,
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
                          color: MijigiColors.primaryLight.withValues(alpha: 0.8),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isCapturing ? 'Opening...' : 'Tap to Scan',
                          style: TextStyle(
                            color: MijigiColors.primaryLight.withValues(alpha: 0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Top label
          Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF111820).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: MijigiColors.border.withValues(alpha: 0.3),
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
                            color: MijigiColors.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'PDF Scanner',
                      style: TextStyle(
                        color: MijigiColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Feature badges at bottom
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: _buildFeatureBadges(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    const cornerSize = 32.0;
    const cornerThickness = 2.5;
    final cornerColor = MijigiColors.primary.withValues(alpha: 0.7);
    const inset = 28.0;

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
                  ? BorderSide(
                      color: cornerColor, width: cornerThickness)
                  : BorderSide.none,
              bottom: alignment == Alignment.bottomLeft ||
                      alignment == Alignment.bottomRight
                  ? BorderSide(
                      color: cornerColor, width: cornerThickness)
                  : BorderSide.none,
              left: alignment == Alignment.topLeft ||
                      alignment == Alignment.bottomLeft
                  ? BorderSide(
                      color: cornerColor, width: cornerThickness)
                  : BorderSide.none,
              right: alignment == Alignment.topRight ||
                      alignment == Alignment.bottomRight
                  ? BorderSide(
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
            const BorderRadius.only(topLeft: Radius.circular(6)),
      ),
      buildCorner(
        alignment: Alignment.topRight,
        borderRadius:
            const BorderRadius.only(topRight: Radius.circular(6)),
      ),
      buildCorner(
        alignment: Alignment.bottomLeft,
        borderRadius:
            const BorderRadius.only(bottomLeft: Radius.circular(6)),
      ),
      buildCorner(
        alignment: Alignment.bottomRight,
        borderRadius:
            const BorderRadius.only(bottomRight: Radius.circular(6)),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: MijigiGradients.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MijigiColors.border.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // PDF icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: MijigiColors.filePdf.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: MijigiColors.filePdf,
                    size: 20,
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
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDate(item.createdAt),
                            style: TextStyle(
                              color: MijigiColors.textTertiary.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MijigiColors.textTertiary.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$pageCount page${pageCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: MijigiColors.textTertiary.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: MijigiColors.textTertiary.withValues(alpha: 0.4),
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
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MijigiColors.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MijigiColors.primary.withValues(alpha: 0.7), size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: MijigiColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
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
      ..color = MijigiColors.border.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    const spacing = 32.0;

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
