enum DownloadStatus { queued, downloading, completed, failed, paused }
enum DownloadType { video, audio, file }

class DownloadItem {
  final String id;
  final String url;
  final String originalUrl;
  final String filename;
  final DownloadType type;
  String? savedPath;
  DownloadStatus status;
  double progress;
  int receivedBytes;
  int totalBytes;
  String? errorMessage;
  final DateTime addedAt;
  String? thumbnailUrl;
  String? platform;

  DownloadItem({
    required this.id,
    required this.url,
    required this.originalUrl,
    required this.filename,
    required this.type,
    this.savedPath,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    required this.addedAt,
    this.thumbnailUrl,
    this.platform,
  });

  String get formattedSize {
    if (totalBytes == 0) return 'Unknown';
    if (totalBytes < 1024) return '${totalBytes}B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)}KB';
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  String get formattedReceived {
    if (receivedBytes < 1024) return '${receivedBytes}B';
    if (receivedBytes < 1024 * 1024) return '${(receivedBytes / 1024).toStringAsFixed(1)}KB';
    return '${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get platformName {
    if (platform != null) return platform!;
    final url = originalUrl.toLowerCase();
    if (url.contains('youtube.com') || url.contains('youtu.be')) return 'YouTube';
    if (url.contains('tiktok.com')) return 'TikTok';
    if (url.contains('instagram.com')) return 'Instagram';
    if (url.contains('twitter.com') || url.contains('x.com')) return 'Twitter/X';
    if (url.contains('facebook.com') || url.contains('fb.watch')) return 'Facebook';
    if (url.contains('terabox')) return 'Terabox';
    if (url.contains('reddit.com')) return 'Reddit';
    if (url.contains('vimeo.com')) return 'Vimeo';
    if (url.contains('twitch.tv')) return 'Twitch';
    return 'Direct Link';
  }
}
