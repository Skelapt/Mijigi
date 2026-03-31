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

  List<CaptureItem> _getClipboardItems(AppProvider provider) {
    return provider.activeItems
        .where((i) => i.type == CaptureType.clipboard)
        .toList();
  }

  /// Group items by date
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
              const SliverToBoxAdapter(child: SizedBox(height: 56)),

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
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      if (_selectMode && _selected.isNotEmpty)
                        GestureDetector(
                          onTap: () => _deleteSelected(provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  MijigiColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Delete ${_selected.length}',
                              style: const TextStyle(
                                color: MijigiColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: MijigiColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: MijigiColors.border),
                            ),
                            child: Text(
                              _selectMode ? 'Cancel' : 'Select',
                              style: const TextStyle(
                                color: MijigiColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Save clipboard button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => _saveClipboard(provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: MijigiColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                MijigiColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.content_paste_go_rounded,
                              color: MijigiColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Save Current Clipboard',
                            style: TextStyle(
                              color: MijigiColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Clipboard items grouped by date
              if (items.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else
                ...grouped.entries.expand((entry) => [
                      // Date header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 8, top: 4),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: MijigiColors.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // 2-column grid of cards
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.8,
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
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.content_paste_off_rounded,
                size: 48,
                color: MijigiColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No clipboard items',
                style: TextStyle(
                    color: MijigiColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Tap "Save Current Clipboard" to save text',
                style:
                    TextStyle(color: MijigiColors.textTertiary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _saveClipboard(AppProvider provider) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      await provider.captureClipboard(data.text!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Clipboard saved'),
            backgroundColor: MijigiColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Clipboard is empty'),
            backgroundColor: MijigiColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _copyToClipboard(CaptureItem item) {
    if (item.rawText != null) {
      Clipboard.setData(ClipboardData(text: item.rawText!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied'),
          duration: const Duration(seconds: 1),
          backgroundColor: MijigiColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? MijigiColors.primary.withValues(alpha: 0.12)
              : MijigiColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? MijigiColors.primary : MijigiColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.rawText ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MijigiColors.textPrimary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  _timeAgo(item.createdAt),
                  style: const TextStyle(
                    color: MijigiColors.textTertiary,
                    fontSize: 10,
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
                        ? MijigiColors.primary
                        : MijigiColors.textTertiary,
                  )
                else
                  const Icon(Icons.content_copy_rounded,
                      size: 12, color: MijigiColors.textTertiary),
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
