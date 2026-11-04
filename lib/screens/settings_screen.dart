import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _defaultQuality = '720';
  bool _audioOnly = false;
  bool _autoDownload = false;
  String _saveLocation = '/storage/emulated/0/Download/MediaDownloader';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultQuality = prefs.getString('quality') ?? '720';
      _audioOnly = prefs.getBool('audioOnly') ?? false;
      _autoDownload = prefs.getBool('autoDownload') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quality', _defaultQuality);
    await prefs.setBool('audioOnly', _audioOnly);
    await prefs.setBool('autoDownload', _autoDownload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সেটিং সংরক্ষিত হয়েছে ✓'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিং', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('সংরক্ষণ'),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(title: 'ডাউনলোড সেটিং'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.high_quality),
                  title: const Text('ডিফল্ট কোয়ালিটি'),
                  subtitle: Text('$_defaultQuality p'),
                  trailing: DropdownButton<String>(
                    value: _defaultQuality,
                    underline: const SizedBox(),
                    items: ['1080', '720', '480', '360', '240', '144']
                        .map((q) => DropdownMenuItem(value: q, child: Text('${q}p')))
                        .toList(),
                    onChanged: (val) => setState(() => _defaultQuality = val!),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.music_note),
                  title: const Text('শুধু Audio ডাউনলোড'),
                  subtitle: const Text('ভিডিও বাদ দিয়ে শুধু গান'),
                  value: _audioOnly,
                  onChanged: (val) => setState(() => _audioOnly = val),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_mode),
                  title: const Text('অটো ডাউনলোড'),
                  subtitle: const Text('লিংক পেস্ট করলেই শুরু হবে'),
                  value: _autoDownload,
                  onChanged: (val) => setState(() => _autoDownload = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'সংরক্ষণ স্থান'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('ডাউনলোড ফোল্ডার'),
              subtitle: Text(_saveLocation,
                  style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'সম্পর্কে'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('অ্যাপ ভার্সন'),
                  trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('সাপোর্টেড সাইট'),
                  trailing: const Text('1000+', style: TextStyle(color: Colors.grey)),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Powered by'),
                  trailing: const Text('Cobalt + yt-dlp', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
