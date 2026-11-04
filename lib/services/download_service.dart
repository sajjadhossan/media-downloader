import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/download_item.dart';
import 'cobalt_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  final List<DownloadItem> _downloads = [];
  final Map<String, CancelToken> _cancelTokens = {};

  List<DownloadItem> get downloads => List.unmodifiable(_downloads);
  List<DownloadItem> get activeDownloads =>
      _downloads.where((d) => d.status == DownloadStatus.downloading).toList();
  List<DownloadItem> get completedDownloads =>
      _downloads.where((d) => d.status == DownloadStatus.completed).toList();

  Function(DownloadItem)? onDownloadUpdated;

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      return await Permission.storage.isGranted;
    }
    return true;
  }

  Future<String> _getDownloadPath(DownloadType type) async {
    Directory? dir;
    try {
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download/MediaDownloader');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      final subDir = type == DownloadType.audio ? 'Audio' : 
                     type == DownloadType.video ? 'Video' : 'Files';
      final fullPath = Directory('${dir.path}/$subDir');
      
      if (!await fullPath.exists()) {
        await fullPath.create(recursive: true);
      }
      return fullPath.path;
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }

  Future<DownloadItem?> startDownload({
    required String url,
    String quality = '720',
    bool audioOnly = false,
    Function(String)? onError,
  }) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        onError?.call('স্টোরেজ পারমিশন দিন');
        return null;
      }

      DownloadInfo? info;
      
      if (CobaltService.isTeraboxUrl(url)) {
        info = await CobaltService.getDownloadInfo(
          url: url,
          quality: quality,
          audioOnly: audioOnly,
        );
      } else if (CobaltService.isDirectDownloadUrl(url)) {
        info = DownloadInfo(
          url: url,
          filename: Uri.parse(url).pathSegments.last,
          type: DownloadType.file,
        );
      } else if (CobaltService.isSupportedUrl(url)) {
        info = await CobaltService.getDownloadInfo(
          url: url,
          quality: quality,
          audioOnly: audioOnly,
        );
      } else {
        // Try as direct download
        info = DownloadInfo(
          url: url,
          filename: 'download_${DateTime.now().millisecondsSinceEpoch}',
          type: DownloadType.file,
        );
      }

      if (info == null) {
        onError?.call('এই লিংক থেকে ডাউনলোড করা যাচ্ছে না');
        return null;
      }

      final item = DownloadItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: info.url,
        originalUrl: url,
        filename: _sanitizeFilename(info.filename),
        type: audioOnly ? DownloadType.audio : info.type,
        addedAt: DateTime.now(),
      );

      _downloads.insert(0, item);
      onDownloadUpdated?.call(item);

      _executeDownload(item);
      return item;
    } catch (e) {
      onError?.call('ত্রুটি: ${e.toString()}');
      return null;
    }
  }

  Future<void> _executeDownload(DownloadItem item) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    try {
      item.status = DownloadStatus.downloading;
      onDownloadUpdated?.call(item);

      final savePath = await _getDownloadPath(item.type);
      final filename = _getUniqueFilename(savePath, item.filename);
      final fullPath = '$savePath/$filename';

      await _dio.download(
        item.url,
        fullPath,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Android 13; Mobile; rv:109.0)',
            'Referer': item.originalUrl,
          },
          receiveTimeout: const Duration(minutes: 30),
        ),
        onReceiveProgress: (received, total) {
          item.receivedBytes = received;
          item.totalBytes = total > 0 ? total : 0;
          item.progress = total > 0 ? received / total : 0;
          onDownloadUpdated?.call(item);
        },
      );

      item.status = DownloadStatus.completed;
      item.savedPath = fullPath;
      item.progress = 1.0;
      onDownloadUpdated?.call(item);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        item.status = DownloadStatus.paused;
      } else {
        item.status = DownloadStatus.failed;
        item.errorMessage = e.message;
      }
      onDownloadUpdated?.call(item);
    } finally {
      _cancelTokens.remove(item.id);
    }
  }

  void cancelDownload(String id) {
    _cancelTokens[id]?.cancel('User cancelled');
    final item = _downloads.firstWhere((d) => d.id == id, orElse: () => throw Exception());
    item.status = DownloadStatus.paused;
    onDownloadUpdated?.call(item);
  }

  Future<void> retryDownload(DownloadItem item) async {
    item.status = DownloadStatus.queued;
    item.progress = 0;
    item.receivedBytes = 0;
    item.errorMessage = null;
    onDownloadUpdated?.call(item);
    _executeDownload(item);
  }

  void removeDownload(String id) {
    _cancelTokens[id]?.cancel();
    _downloads.removeWhere((d) => d.id == id);
  }

  String _sanitizeFilename(String filename) {
    String clean = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    if (!clean.contains('.')) {
      clean += '.mp4';
    }
    return clean;
  }

  String _getUniqueFilename(String dir, String filename) {
    final file = File('$dir/$filename');
    if (!file.existsSync()) return filename;

    final dotIndex = filename.lastIndexOf('.');
    final name = dotIndex != -1 ? filename.substring(0, dotIndex) : filename;
    final ext = dotIndex != -1 ? filename.substring(dotIndex) : '';

    int counter = 1;
    while (File('$dir/${name}_$counter$ext').existsSync()) {
      counter++;
    }
    return '${name}_$counter$ext';
  }
}
