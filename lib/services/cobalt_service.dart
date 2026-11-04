import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/download_item.dart';

class CobaltService {
  static const String _baseUrl = 'https://api.cobalt.tools/api/json';

  static bool isSupportedUrl(String url) {
    final supported = [
      'youtube.com', 'youtu.be',
      'tiktok.com',
      'instagram.com',
      'twitter.com', 'x.com',
      'facebook.com', 'fb.watch',
      'reddit.com',
      'twitch.tv',
      'vimeo.com',
      'dailymotion.com',
      'soundcloud.com',
      'bilibili.com',
      'pinterest.com',
      'tumblr.com',
      'streamable.com',
    ];
    return supported.any((domain) => url.contains(domain));
  }

  static bool isTeraboxUrl(String url) {
    return url.contains('terabox.com') ||
        url.contains('teraboxapp.com') ||
        url.contains('1024tera.com') ||
        url.contains('4funbox.com') ||
        url.contains('momerybox.com') ||
        url.contains('tibibox.com');
  }

  static bool isDirectDownloadUrl(String url) {
    final extensions = ['.mp4', '.mp3', '.mkv', '.avi', '.mov', '.pdf', '.zip', '.rar'];
    return extensions.any((ext) => url.toLowerCase().contains(ext));
  }

  static Future<DownloadInfo?> getDownloadInfo({
    required String url,
    required String quality,
    required bool audioOnly,
  }) async {
    try {
      if (isTeraboxUrl(url)) {
        return await _getTeraboxInfo(url);
      }

      if (isDirectDownloadUrl(url)) {
        return DownloadInfo(
          url: url,
          filename: url.split('/').last,
          type: DownloadType.video,
        );
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'url': url,
          'vQuality': quality,
          'isAudioOnly': audioOnly,
          'isNoTTWatermark': true,
          'isTTFullAudio': true,
          'filenamePattern': 'basic',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'stream' || status == 'redirect') {
          return DownloadInfo(
            url: data['url'],
            filename: data['filename'] ?? 'download',
            type: audioOnly ? DownloadType.audio : DownloadType.video,
          );
        } else if (status == 'picker') {
          final items = data['picker'] as List;
          if (items.isNotEmpty) {
            return DownloadInfo(
              url: items[0]['url'],
              filename: 'download',
              type: DownloadType.video,
              pickerItems: items.map((e) => e['url'] as String).toList(),
            );
          }
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  static Future<DownloadInfo?> _getTeraboxInfo(String url) async {
    try {
      // Terabox requires special handling via their share API
      final shareId = _extractTeraboxShareId(url);
      if (shareId == null) return null;

      final apiUrl = 'https://www.terabox.com/share/list?shorturl=$shareId&root=1';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Android 13; Mobile; rv:109.0) Gecko/116.0 Firefox/116.0',
          'Referer': 'https://www.terabox.com/',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errno'] == 0 && data['list'] != null) {
          final list = data['list'] as List;
          if (list.isNotEmpty) {
            final file = list[0];
            return DownloadInfo(
              url: file['dlink'] ?? '',
              filename: file['server_filename'] ?? 'terabox_file',
              type: DownloadType.file,
            );
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String? _extractTeraboxShareId(String url) {
    final regex = RegExp(r'/s/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }
}

class DownloadInfo {
  final String url;
  final String filename;
  final DownloadType type;
  final List<String>? pickerItems;

  DownloadInfo({
    required this.url,
    required this.filename,
    required this.type,
    this.pickerItems,
  });
}
