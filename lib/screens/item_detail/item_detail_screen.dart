import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:video_player/video_player.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initVideo(String path) {
    if (_videoController != null) return;
    _videoController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        if (mounted) setState(() => _videoInitialized = true);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final item =
            provider.items.where((i) => i.id == widget.itemId).firstOrNull;
        if (item == null) {
          return Scaffold(
            backgroundColor: MijigiColors.background,
            appBar: AppBar(),
            body: const Center(
              child: Text('Item not found',
                  style: TextStyle(color: MijigiColors.textTertiary)),
            ),
          );
        }

        final isPdf = item.filePath != null &&
            item.filePath!.toLowerCase().endsWith('.pdf');

        return Scaffold(
          backgroundColor: MijigiColors.background,
          appBar: AppBar(
            backgroundColor: MijigiColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  item.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 20,
                  color: item.isPinned ? MijigiColors.primary : null,
                ),
                onPressed: () => provider.togglePin(item.id),
              ),
              PopupMenuButton<String>(
                color: MijigiColors.surfaceLight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) => _handleAction(value, provider, item),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'share',
                      child: Row(children: [
                        Icon(Icons.share_rounded,
                            size: 18, color: MijigiColors.textSecondary),
                        SizedBox(width: 10),
                        Text('Share'),
                      ])),
                  const PopupMenuItem(
                      value: 'copy',
                      child: Row(children: [
                        Icon(Icons.copy_rounded,
                            size: 18, color: MijigiColors.textSecondary),
                        SizedBox(width: 10),
                        Text('Copy text'),
                      ])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: MijigiColors.error),
                        SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: MijigiColors.error)),
                      ])),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PDF card
                if (isPdf) ...[
                  _buildPdfCard(item),
                  const SizedBox(height: 16),
                ]
                // Video player
                else if (item.type == CaptureType.video && item.filePath != null) ...[
                  _buildVideoPlayer(item.filePath!),
                  const SizedBox(height: 16),
                ]
                // Image
                else if (item.hasImage && item.filePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(item.filePath!),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: MijigiColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: MijigiColors.textTertiary, size: 40)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]
                // Document text content (no image)
                else if (item.type == CaptureType.document &&
                    item.rawText != null &&
                    item.rawText!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: MijigiColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MijigiColors.border),
                    ),
                    child: SelectableText(
                      item.rawText!,
                      style: const TextStyle(
                        color: MijigiColors.textPrimary,
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Labels (what ML Kit sees in the photo)
                if (item.labels.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.labels.map((label) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: MijigiColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: MijigiColors.primary
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: MijigiColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Extracted data action cards
                if (item.extractedData != null &&
                    item.extractedData!.isNotEmpty) ...[
                  ...item.extractedData!.entries.map((entry) {
                    return _buildExtractedDataSection(entry.key, entry.value);
                  }),
                  const SizedBox(height: 8),
                ],

                // OCR text (only if not already shown as document content above)
                if (item.rawText != null &&
                    item.rawText!.isNotEmpty &&
                    !(item.type == CaptureType.document &&
                        !item.hasImage &&
                        !isPdf)) ...[
                  const Text(
                    'Text',
                    style: TextStyle(
                      color: MijigiColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MijigiColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MijigiColors.border),
                    ),
                    child: SelectableText(
                      item.rawText!,
                      style: const TextStyle(
                        color: MijigiColors.textPrimary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Metadata
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(
                    color: MijigiColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// PDF file card with icon, filename, and open button
  Widget _buildVideoPlayer(String path) {
    _initVideo(path);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: MijigiColors.surfaceLight,
        child: _videoInitialized && _videoController != null
            ? Column(
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: MijigiColors.surface,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _videoController!.value.isPlaying
                                  ? _videoController!.pause()
                                  : _videoController!.play();
                            });
                          },
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: MijigiColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: VideoProgressIndicator(
                            _videoController!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: MijigiColors.primary,
                              bufferedColor: MijigiColors.surfaceBright,
                              backgroundColor: MijigiColors.border,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_videoController!.value.duration),
                          style: const TextStyle(
                            color: MijigiColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: MijigiColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildPdfCard(CaptureItem item) {
    final fileName = item.filePath!.split('/').last;
    final file = File(item.filePath!);
    final fileExists = file.existsSync();
    final fileSize = fileExists ? file.lengthSync() : 0;
    final sizeStr = fileSize > 1048576
        ? '${(fileSize / 1048576).toStringAsFixed(1)} MB'
        : '${(fileSize / 1024).toStringAsFixed(0)} KB';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MijigiColors.filePdf.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MijigiColors.filePdf.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: MijigiColors.filePdf.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: MijigiColors.filePdf,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            fileName,
            style: const TextStyle(
              color: MijigiColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            fileExists ? 'PDF Document  -  $sizeStr' : 'PDF Document',
            style: const TextStyle(
              color: MijigiColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openPdf(item.filePath!),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MijigiColors.filePdf,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPdf(String path) async {
    try {
      await OpenFile.open(path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open PDF',
                style: TextStyle(color: Colors.white)),
            backgroundColor: MijigiColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// Build extracted data section with action cards
  Widget _buildExtractedDataSection(String key, dynamic value) {
    final items = value is List ? value.cast<String>() : [value.toString()];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => _buildActionCard(key, item)).toList(),
      ),
    );
  }

  Widget _buildActionCard(String key, String value) {
    final config = _actionCardConfig(key);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.color.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: config.hasAction ? () => _launchAction(key, value) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Leading icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    config.icon,
                    color: config.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.label,
                        style: TextStyle(
                          color: config.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Copy button
                _buildSmallIconButton(
                  icon: Icons.content_copy_rounded,
                  color: MijigiColors.textTertiary,
                  onTap: () => _copyToClipboard(value),
                ),
                // Action button (if applicable)
                if (config.hasAction) ...[
                  const SizedBox(width: 6),
                  _buildSmallIconButton(
                    icon: config.actionIcon!,
                    color: config.color,
                    onTap: () => _launchAction(key, value),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  _ActionCardConfig _actionCardConfig(String key) {
    return switch (key) {
      'emails' => _ActionCardConfig(
          icon: Icons.mail_rounded,
          label: 'EMAIL',
          color: const Color(0xFFEA4335), // Gmail red
          hasAction: true,
          actionIcon: Icons.send_rounded,
        ),
      'phones' => _ActionCardConfig(
          icon: Icons.phone_rounded,
          label: 'PHONE',
          color: const Color(0xFF34A853), // Green
          hasAction: true,
          actionIcon: Icons.call_rounded,
        ),
      'urls' => _ActionCardConfig(
          icon: Icons.language_rounded,
          label: 'URL',
          color: const Color(0xFF4285F4), // Blue
          hasAction: true,
          actionIcon: Icons.open_in_new_rounded,
        ),
      'amounts' => _ActionCardConfig(
          icon: Icons.payments_rounded,
          label: 'AMOUNT',
          color: MijigiColors.fileSheet, // Green
          hasAction: false,
          actionIcon: null,
        ),
      'dates' => _ActionCardConfig(
          icon: Icons.event_rounded,
          label: 'DATE',
          color: MijigiColors.warning,
          hasAction: false,
          actionIcon: null,
        ),
      _ => _ActionCardConfig(
          icon: Icons.data_object_rounded,
          label: key.toUpperCase(),
          color: MijigiColors.textSecondary,
          hasAction: false,
          actionIcon: null,
        ),
    };
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text',
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 1),
        backgroundColor: MijigiColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _launchAction(String key, String value) async {
    Uri? uri;
    switch (key) {
      case 'emails':
        uri = Uri(scheme: 'mailto', path: value);
        break;
      case 'phones':
        uri =
            Uri(scheme: 'tel', path: value.replaceAll(RegExp(r'[^\d+]'), ''));
        break;
      case 'urls':
        var url = value;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        uri = Uri.tryParse(url);
        break;
    }
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not open',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: MijigiColors.surfaceLight,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _handleAction(String action, AppProvider provider, CaptureItem item) {
    switch (action) {
      case 'share':
        final text = item.rawText ?? item.displayTitle;
        Share.share(text);
        break;
      case 'copy':
        if (item.rawText != null) {
          Clipboard.setData(ClipboardData(text: item.rawText!));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Copied to clipboard',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: MijigiColors.surfaceLight,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        break;
      case 'delete':
        provider.deleteItem(item.id);
        Navigator.pop(context);
        break;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $amPm';
  }
}

class _ActionCardConfig {
  final IconData icon;
  final String label;
  final Color color;
  final bool hasAction;
  final IconData? actionIcon;

  const _ActionCardConfig({
    required this.icon,
    required this.label,
    required this.color,
    required this.hasAction,
    required this.actionIcon,
  });
}
