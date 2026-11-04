import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/download_item.dart';
import '../services/download_service.dart';
import '../services/cobalt_service.dart';
import '../widgets/download_card.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final DownloadService _downloadService = DownloadService();
  final FocusNode _focusNode = FocusNode();

  int _selectedIndex = 0;
  bool _isLoading = false;
  String _selectedQuality = '720';
  bool _audioOnly = false;
  List<DownloadItem> _recentDownloads = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _qualities = ['1080', '720', '480', '360', '240', '144'];

  final List<_PlatformInfo> _supportedPlatforms = [
    _PlatformInfo('YouTube', Icons.play_circle_filled, Color(0xFFFF0000)),
    _PlatformInfo('TikTok', Icons.music_note, Color(0xFF000000)),
    _PlatformInfo('Instagram', Icons.camera_alt, Color(0xFFE1306C)),
    _PlatformInfo('Facebook', Icons.facebook, Color(0xFF1877F2)),
    _PlatformInfo('Twitter/X', Icons.tag, Color(0xFF1DA1F2)),
    _PlatformInfo('Terabox', Icons.cloud_download, Color(0xFF0066FF)),
    _PlatformInfo('Reddit', Icons.reddit, Color(0xFFFF4500)),
    _PlatformInfo('Vimeo', Icons.video_library, Color(0xFF1AB7EA)),
    _PlatformInfo('Twitch', Icons.live_tv, Color(0xFF9146FF)),
    _PlatformInfo('+ 1000 More', Icons.language, Color(0xFF6C63FF)),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _downloadService.onDownloadUpdated = (item) {
      if (mounted) setState(() {
        _recentDownloads = _downloadService.downloads.take(5).toList();
      });
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar('একটি লিংক দিন', isError: true);
      return;
    }

    if (!url.startsWith('http')) {
      _showSnackBar('সঠিক লিংক দিন (http/https)', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final item = await _downloadService.startDownload(
      url: url,
      quality: _selectedQuality,
      audioOnly: _audioOnly,
      onError: (msg) => _showSnackBar(msg, isError: true),
    );

    setState(() {
      _isLoading = false;
      if (item != null) {
        _urlController.clear();
        _recentDownloads = _downloadService.downloads.take(5).toList();
        _showSnackBar('ডাউনলোড শুরু হয়েছে! ✓');
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
      _showSnackBar('লিংক পেস্ট হয়েছে');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          const DownloadsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'ডাউনলোড',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'ফাইল',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'সেটিং',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'Media Downloader',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.cloud_download, size: 60, color: Colors.white30),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showInfoDialog,
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // URL Input Card
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'লিংক দিন',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'YouTube, TikTok, Instagram, Terabox লিংক...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.link),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.content_paste),
                            onPressed: _pasteFromClipboard,
                            tooltip: 'পেস্ট করুন',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        keyboardType: TextInputType.url,
                        onSubmitted: (_) => _handleDownload(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedQuality,
                              decoration: InputDecoration(
                                labelText: 'কোয়ালিটি',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                filled: true,
                                fillColor: colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              ),
                              items: _qualities
                                  .map((q) => DropdownMenuItem(
                                        value: q,
                                        child: Text('${q}p'),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedQuality = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilterChip(
                            label: const Text('শুধু Audio'),
                            selected: _audioOnly,
                            onSelected: (val) => setState(() => _audioOnly = val),
                            avatar: const Icon(Icons.music_note, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleDownload,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(
                            _isLoading ? 'লিংক যাচাই করছি...' : 'ডাউনলোড করুন',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Supported Platforms
              Text(
                'সাপোর্টেড প্ল্যাটফর্ম',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _supportedPlatforms
                    .map((p) => _PlatformChip(info: p))
                    .toList(),
              ),

              // Recent Downloads
              if (_recentDownloads.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'সাম্প্রতিক ডাউনলোড',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 1),
                      child: const Text('সব দেখুন'),
                    ),
                  ],
                ),
                ..._recentDownloads.map((item) => DownloadCard(
                      item: item,
                      onCancel: () => _downloadService.cancelDownload(item.id),
                      onRetry: () => _downloadService.retryDownload(item),
                    )),
              ],

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Downloader'),
        content: const Text(
          'এই অ্যাপ দিয়ে YouTube, TikTok, Instagram, Facebook, Twitter/X, Terabox সহ ১০০০+ ওয়েবসাইট থেকে ভিডিও ও অডিও ডাউনলোড করুন।\n\n'
          'ডাউনলোড ফোল্ডার:\n/Storage/Download/MediaDownloader/',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }
}

class _PlatformInfo {
  final String name;
  final IconData icon;
  final Color color;
  const _PlatformInfo(this.name, this.icon, this.color);
}

class _PlatformChip extends StatelessWidget {
  final _PlatformInfo info;
  const _PlatformChip({required this.info});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(info.icon, size: 16, color: info.color),
      label: Text(info.name, style: const TextStyle(fontSize: 12)),
      backgroundColor: info.color.withOpacity(0.1),
      side: BorderSide(color: info.color.withOpacity(0.3)),
    );
  }
}
