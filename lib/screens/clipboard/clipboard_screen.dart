import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ClipboardScreen extends StatefulWidget {
  const ClipboardScreen({super.key});

  @override
  State<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends State<ClipboardScreen> {
  final Set<String> _selected = {};
  bool _selectMode = false;

  @override
  void initState() {
    super.initState();
    // Try auto-capture on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().checkClipboardNow();
    });
  }

  List<CaptureItem> _getClipboardItems(AppProvider provider) {
    return provider.activeItems
        .where((i) => i.type == CaptureType.clipboard)
        .toList();
  }

  Map<String, List<CaptureItem>> _groupByDate(List<CaptureItem> items) {
    final grouped = <String, List<CaptureItem>>{};
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in items) {
      String key;
      if (_isSameDay(item.createdAt, today)) {
        key = 'Today';
      } else if (_isSameDay(item.createdAt, yesterday)) {
        key = 'Yesterday';
      } else {
        key = DateFormat('MMM d, yyyy').format(item.createdAt);
      }
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final items = _getClipboardItems(provider);
        final grouped = _groupByDate(items);

        return Scaffold(
          backgroundColor: MijigiColors.background,
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // Title bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Clipboard',
                        style: TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      if (_selectMode && _selected.isNotEmpty)
                        GestureDetector(
                          onTap: () => _deleteSelected(provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  MijigiColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: MijigiColors.error.withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'Delete ${_selected.length}',
                              style: const TextStyle(
                                color: MijigiColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectMode = !_selectMode;
                            if (!_selectMode) _selected.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: MijigiColors.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: MijigiColors.border.withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _selectMode ? 'Cancel' : 'Select',
                              style: const TextStyle(
                                color: MijigiColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Two buttons: paste from clipboard + type manually
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _saveFromClipboard(provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: MijigiGradients.buttonGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: MijigiColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.content_paste_go_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text(
                                  'Paste & Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showManualInput(provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: MijigiGradients.cardGradient,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: MijigiColors.border.withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded,
                                    color: MijigiColors.textSecondary, size: 18),
                                SizedBox(width: 10),
                                Text(
                                  'Type & Save',
                                  style: TextStyle(
                                    color: MijigiColors.textSecondary,
                                    fontSize: 14,
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
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // Clipboard items grouped by date
              if (items.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else
                ...grouped.entries.expand((entry) => [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 10, top: 6),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: MijigiColors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.6,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = entry.value[index];
                              return _ClipboardCard(
                                item: item,
                                isSelected: _selected.contains(item.id),
                                selectMode: _selectMode,
                                onTap: () {
                                  if (_selectMode) {
                                    setState(() {
                                      if (_selected.contains(item.id)) {
                                        _selected.remove(item.id);
                                      } else {
                                        _selected.add(item.id);
                                      }
                                    });
                                  } else {
                                    _copyToClipboard(item);
                                  }
                                },
                                onLongPress: () {
                                  if (!_selectMode) {
                                    setState(() {
                                      _selectMode = true;
                                      _selected.add(item.id);
                                    });
                                    HapticFeedback.mediumImpact();
                                  }
                                },
                              );
                            },
                            childCount: entry.value.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    ]),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.content_paste_off_rounded,
                size: 44,
                color: MijigiColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('No clipboard items',
                style: TextStyle(
                    color: MijigiColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text(
                'Copy text anywhere, then tap "Paste & Save"\nor type text manually',
                style: TextStyle(color: MijigiColors.textTertiary, fontSize: 13,
                    fontWeight: FontWeight.w400),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _saveFromClipboard(AppProvider provider) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.trim().isNotEmpty) {
        await provider.captureClipboard(data.text!.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Saved!', style: TextStyle(color: Colors.white)),
              backgroundColor: MijigiColors.surfaceLight,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      } else {
        // Clipboard empty or couldn't read - show manual input
        if (mounted) _showManualInput(provider);
      }
    } catch (e) {
      // Android clipboard restrictions - fallback to manual input
      if (mounted) _showManualInput(provider);
    }
  }

  void _showManualInput(AppProvider provider) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        decoration: MijigiGradients.frostedSheet(),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: MijigiColors.textTertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Save to Clipboard',
                  style: TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.3)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                style: const TextStyle(color: MijigiColors.textPrimary, fontSize: 15,
                    fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  hintText: 'Paste or type text here...',
                  hintStyle: TextStyle(color: MijigiColors.textTertiary.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: MijigiColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: MijigiColors.border.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: MijigiColors.border.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: MijigiColors.primary, width: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: MijigiGradients.buttonGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        await provider.captureClipboard(text);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Saved!',
                                  style: TextStyle(color: Colors.white)),
                              backgroundColor: MijigiColors.surfaceLight,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(CaptureItem item) {
    if (item.rawText != null) {
      Clipboard.setData(ClipboardData(text: item.rawText!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied', style: TextStyle(color: Colors.white)),
          duration: const Duration(seconds: 1),
          backgroundColor: MijigiColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _deleteSelected(AppProvider provider) {
    for (final id in _selected) {
      provider.deleteItem(id);
    }
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
  }
}

class _ClipboardCard extends StatelessWidget {
  final CaptureItem item;
  final bool isSelected;
  final bool selectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ClipboardCard({
    required this.item,
    required this.isSelected,
    required this.selectMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected ? null : MijigiGradients.cardGradient,
          color: isSelected
              ? MijigiColors.primary.withValues(alpha: 0.08)
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? MijigiColors.primary.withValues(alpha: 0.3)
                : MijigiColors.border.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.rawText ?? '',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MijigiColors.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _timeAgo(item.createdAt),
                  style: TextStyle(
                    color: MijigiColors.textTertiary.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                if (selectMode)
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: isSelected
                        ? MijigiColors.primaryLight
                        : MijigiColors.textTertiary,
                  )
                else
                  Icon(Icons.content_copy_rounded,
                      size: 12,
                      color: MijigiColors.textTertiary.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}
