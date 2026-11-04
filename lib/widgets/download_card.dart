import 'package:flutter/material.dart';
import '../models/download_item.dart';

class DownloadCard extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  const DownloadCard({
    super.key,
    required this.item,
    this.onCancel,
    this.onRetry,
    this.onOpen,
    this.onDelete,
  });

  Color _getStatusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (item.status) {
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.downloading:
        return colorScheme.primary;
      case DownloadStatus.paused:
        return Colors.orange;
      default:
        return colorScheme.outline;
    }
  }

  IconData _getPlatformIcon() {
    switch (item.platformName) {
      case 'YouTube':
        return Icons.play_circle_filled;
      case 'TikTok':
        return Icons.music_note;
      case 'Instagram':
        return Icons.camera_alt;
      case 'Twitter/X':
        return Icons.tag;
      case 'Facebook':
        return Icons.facebook;
      case 'Terabox':
        return Icons.cloud_download;
      default:
        return item.type == DownloadType.audio
            ? Icons.audio_file
            : item.type == DownloadType.video
                ? Icons.video_file
                : Icons.insert_drive_file;
    }
  }

  String _getStatusText() {
    switch (item.status) {
      case DownloadStatus.queued:
        return 'অপেক্ষায়...';
      case DownloadStatus.downloading:
        return '${item.formattedReceived} / ${item.formattedSize}';
      case DownloadStatus.completed:
        return 'সম্পন্ন ✓';
      case DownloadStatus.failed:
        return 'ব্যর্থ: ${item.errorMessage ?? 'অজানা ত্রুটি'}';
      case DownloadStatus.paused:
        return 'থামানো হয়েছে';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getPlatformIcon(), color: statusColor, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.filename,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.platformName,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.type == DownloadType.audio ? 'Audio' : 'Video',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildActionButton(context),
              ],
            ),
            if (item.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.status == DownloadStatus.downloading)
                  Text(
                    '${(item.progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.downloading:
        return IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.stop_circle_outlined),
          color: Colors.red,
        );
      case DownloadStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.folder_open),
              color: Colors.green,
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
          ],
        );
      case DownloadStatus.failed:
      case DownloadStatus.paused:
        return IconButton(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          color: Theme.of(context).colorScheme.primary,
        );
      default:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
    }
  }
}
