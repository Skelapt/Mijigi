import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';

enum ScanFilter { original, bw, grayscale, enhanced }

class _ScannedPage {
  String imagePath;
  int rotation;
  ScanFilter filter;

  _ScannedPage({
    required this.imagePath,
    required this.rotation,
    required this.filter,
  });
}

class ScannerReviewScreen extends StatefulWidget {
  final String initialImagePath;

  const ScannerReviewScreen({super.key, required this.initialImagePath});

  @override
  State<ScannerReviewScreen> createState() => _ScannerReviewScreenState();
}

class _ScannerReviewScreenState extends State<ScannerReviewScreen> {
  final List<_ScannedPage> _pages = [];
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  bool _isCreating = false;
  final TextEditingController _nameController =
      TextEditingController(text: 'Scanned Document');

  @override
  void initState() {
    super.initState();
    _pages.add(_ScannedPage(imagePath: widget.initialImagePath, rotation: 0, filter: ScanFilter.original));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MijigiColors.background,
      appBar: AppBar(
        backgroundColor: MijigiColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_pages.length} ${_pages.length == 1 ? "page" : "pages"}',
          style: const TextStyle(
            color: MijigiColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createPdf,
            child: Text(
              'Create PDF',
              style: TextStyle(
                color: _isCreating
                    ? MijigiColors.textTertiary
                    : MijigiColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Document name input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(
                color: MijigiColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.edit_rounded,
                    color: MijigiColors.textTertiary, size: 18),
                hintText: 'Document name',
                hintStyle:
                    const TextStyle(color: MijigiColors.textTertiary),
                filled: true,
                fillColor: MijigiColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: MijigiColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: MijigiColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: MijigiColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),

          // Page viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColorFiltered(
                      colorFilter: _getColorFilter(page.filter),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationZ(
                            page.rotation * 3.14159265 / 180),
                        child: Image.file(
                          File(page.imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: MijigiColors.surfaceLight,
                            child: const Center(
                              child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: MijigiColors.textTertiary,
                                  size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Page indicator
          if (_pages.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  return Container(
                    width: i == _currentPage ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? MijigiColors.primary
                          : MijigiColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ScanFilter.values.map((filter) {
                final isActive =
                    _pages[_currentPage].filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _pages[_currentPage].filter = filter;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? MijigiColors.primary
                            : MijigiColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? MijigiColors.primary
                              : MijigiColors.border,
                        ),
                      ),
                      child: Text(
                        _filterName(filter),
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : MijigiColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Action buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionBtn(
                  icon: Icons.rotate_right_rounded,
                  label: 'Rotate',
                  onTap: () => setState(() {
                    _pages[_currentPage].rotation =
                        (_pages[_currentPage].rotation + 90) % 360;
                  }),
                ),
                _ActionBtn(
                  icon: Icons.add_a_photo_rounded,
                  label: 'Add Page',
                  onTap: _addPage,
                ),
                if (_pages.length > 1)
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove',
                    color: MijigiColors.error,
                    onTap: () => setState(() {
                      _pages.removeAt(_currentPage);
                      if (_currentPage >= _pages.length) {
                        _currentPage = _pages.length - 1;
                      }
                      _pageController.jumpToPage(_currentPage);
                    }),
                  ),
                if (_pages.length > 1 && _currentPage > 0)
                  _ActionBtn(
                    icon: Icons.arrow_back_rounded,
                    label: 'Move Left',
                    onTap: () => setState(() {
                      final page = _pages.removeAt(_currentPage);
                      _pages.insert(_currentPage - 1, page);
                      _currentPage--;
                      _pageController.jumpToPage(_currentPage);
                    }),
                  ),
                if (_pages.length > 1 &&
                    _currentPage < _pages.length - 1)
                  _ActionBtn(
                    icon: Icons.arrow_forward_rounded,
                    label: 'Move Right',
                    onTap: () => setState(() {
                      final page = _pages.removeAt(_currentPage);
                      _pages.insert(_currentPage + 1, page);
                      _currentPage++;
                      _pageController.jumpToPage(_currentPage);
                    }),
                  ),
              ],
            ),
          ),

          // Creating indicator
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MijigiColors.primary),
                  ),
                  SizedBox(width: 10),
                  Text('Creating PDF...',
                      style: TextStyle(
                          color: MijigiColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  ColorFilter _getColorFilter(ScanFilter filter) {
    switch (filter) {
      case ScanFilter.original:
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
      case ScanFilter.bw:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ScanFilter.grayscale:
        return const ColorFilter.matrix([
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ScanFilter.enhanced:
        return const ColorFilter.matrix([
          1.3, 0, 0, 0, -30,
          0, 1.3, 0, 0, -30,
          0, 0, 1.3, 0, -30,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  String _filterName(ScanFilter filter) => switch (filter) {
    ScanFilter.original => 'Original',
    ScanFilter.bw => 'B&W',
    ScanFilter.grayscale => 'Grayscale',
    ScanFilter.enhanced => 'Enhanced',
  };

  Future<void> _addPage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (photo != null) {
      setState(() {
        _pages.add(_ScannedPage(imagePath: photo.path, rotation: 0, filter: ScanFilter.original));
        _currentPage = _pages.length - 1;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createPdf() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    HapticFeedback.mediumImpact();

    final pdfService = PdfService();
    final pdfPath = await pdfService.createPdfFromImages(
      imagePaths: _pages.map((p) => p.imagePath).toList(),
      fileName: _nameController.text.isEmpty
          ? 'Scanned Document'
          : _nameController.text,
      rotations: _pages.map((p) => p.rotation).toList(),
    );

    if (pdfPath != null && mounted) {
      final provider = context.read<AppProvider>();
      await provider.captureScannedDocument(
        pdfPath: pdfPath,
        title: _nameController.text.isEmpty
            ? 'Scanned Document'
            : _nameController.text,
        pageCount: _pages.length,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF created: ${_pages.length} pages',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: MijigiColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to create PDF',
              style: TextStyle(color: Colors.white)),
          backgroundColor: MijigiColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    setState(() => _isCreating = false);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? MijigiColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: c, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
