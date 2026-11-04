import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../models/download_item.dart';
import '../services/download_service.dart';
import '../widgets/download_card.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  final DownloadService _downloadService = DownloadService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _downloadService.onDownloadUpdated = (_) {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = _downloadService.downloads;
    final active = all.where((d) =>
        d.status == DownloadStatus.downloading ||
        d.status == DownloadStatus.queued).toList();
    final completed = all.where((d) => d.status == DownloadStatus.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ডাউনলোড', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'সব (${all.length})'),
            Tab(text: 'চলছে (${active.length})'),
            Tab(text: 'সম্পন্ন (${completed.length})'),
          ],
        ),
        actions: [
          if (all.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'সব মুছুন',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(all),
          _buildList(active),
          _buildList(completed),
        ],
      ),
    );
  }

  Widget _buildList(List<DownloadItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_done, size: 80,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'কোনো ডাউনলোড নেই',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return DownloadCard(
          item: item,
          onCancel: () => setState(() => _downloadService.cancelDownload(item.id)),
          onRetry: () => setState(() => _downloadService.retryDownload(item)),
          onOpen: () => _openFile(item),
          onDelete: () => _deleteItem(item),
        );
      },
    );
  }

  Future<void> _openFile(DownloadItem item) async {
    if (item.savedPath != null) {
      await OpenFilex.open(item.savedPath!);
    }
  }

  Future<void> _deleteItem(DownloadItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ফাইল মুছবেন?'),
        content: const Text('ডিভাইস থেকেও ফাইল মুছে যাবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (item.savedPath != null) {
        final file = File(item.savedPath!);
        if (await file.exists()) await file.delete();
      }
      setState(() => _downloadService.removeDownload(item.id));
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সব মুছবেন?'),
        content: const Text('ডাউনলোড তালিকা পরিষ্কার হবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final item in _downloadService.downloads.toList()) {
        _downloadService.removeDownload(item.id);
      }
      setState(() {});
    }
  }
}
