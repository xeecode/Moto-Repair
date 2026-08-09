import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/db_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  List<FileSystemEntity> _backups = [];
  bool _busy = false;
  final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final backups = await DBHelper.instance.listBackups();
    setState(() => _backups = backups);
  }

  DateTime? _parseTimestamp(String path) {
    final fileName = path.split('/').last;
    final match = RegExp(r'backup_(.+)\.db').firstMatch(fileName);
    if (match == null) return null;
    final raw = match.group(1)!; // e.g. 2026-08-05T05-23-10.123456
    final parts = raw.split('T');
    if (parts.length != 2) return DateTime.tryParse(raw);
    final datePart = parts[0]; // 2026-08-05 (keep dashes)
    final timePart = parts[1].replaceAll('-', ':'); // 05:23:10.123456
    return DateTime.tryParse('${datePart}T$timePart');
  }

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      await DBHelper.instance.createBackup();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _shareBackup(String path) async {
    try {
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Motorcycle Shop - Data Backup',
        text: 'Shop data backup file. Keep it safe - you can restore it '
            'inside the app anytime using "Import Backup from Device".',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share backup: $e')),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );
      if (result == null || result.files.single.path == null) return;

      final pickedPath = result.files.single.path!;
      if (!pickedPath.endsWith('.db')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select a valid backup (.db) file.')),
          );
        }
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Backup'),
          content: const Text(
              'This will replace all current data on this phone with the selected backup file. Continue?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Import', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (confirm != true) return;

      setState(() => _busy = true);
      await DBHelper.instance.restoreBackup(pickedPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Backup imported successfully! Restart the app to see all changes.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
            'This will replace all current data with this backup. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await DBHelper.instance.restoreBackup(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data restored successfully! Restart the app to see all changes.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _deleteBackup(String path) async {
    await DBHelper.instance.deleteBackup(path);
    _load();
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete ALL parts, bills, suppliers, purchases and expenses (backups are not affected). This cannot be undone. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete Everything', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await DBHelper.instance.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared. Ready for real shop data!')),
        );
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('About Backups',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Backups save all inventory, bills, purchases and expenses. '
                  'Create a backup, then tap Share on it to send the file to '
                  'WhatsApp, your Google Drive app, or email — completely '
                  'manual, no login required. On another phone, use "Import '
                  'Backup from Device" and pick that same file to bring your '
                  'data over.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _createBackup,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.backup),
                label: const Text('Create Backup Now'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _importBackup,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Import Backup from Device'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Danger Zone',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Permanently erase all parts, bills, suppliers, purchases and '
                  'expenses from this device. Take a backup first if you might '
                  'need this data again.',
                  style: TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _clearAllData,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Clear All Data'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Saved Backups (${_backups.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: _backups.isEmpty
                ? const Center(child: Text('No backups yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _backups.length,
                    itemBuilder: (ctx, i) {
                      final file = _backups[i];
                      final dt = _parseTimestamp(file.path);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.description_outlined)),
                          title: Text(
                              dt != null ? _dateFmt.format(dt) : file.path.split('/').last),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'share') _shareBackup(file.path);
                              if (v == 'restore') _restoreBackup(file.path);
                              if (v == 'delete') _deleteBackup(file.path);
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                  value: 'share',
                                  child: Text('Share (WhatsApp/Drive/Email)')),
                              const PopupMenuItem(
                                  value: 'restore', child: Text('Restore')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
