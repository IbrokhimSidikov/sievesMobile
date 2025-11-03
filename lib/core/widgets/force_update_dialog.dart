import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/version/version_service.dart';

class ForceUpdateDialog extends StatelessWidget {
  final UpdateStatus updateStatus;

  const ForceUpdateDialog({
    super.key,
    required this.updateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !updateStatus.isUpdateRequired,
      child: AlertDialog(
        title: Text(
          updateStatus.isUpdateRequired ? 'Update Required' : 'Update Available',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(updateStatus.updateMessage),
            const SizedBox(height: 16),
            Text(
              'Current Version: ${updateStatus.currentVersion}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Latest Version: ${updateStatus.latestVersion}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (updateStatus.isUpdateRequired)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'You must update to continue using the app.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (!updateStatus.isUpdateRequired)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () => _openStore(updateStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: updateStatus.isUpdateRequired 
                  ? Colors.red 
                  : Theme.of(context).primaryColor,
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore(UpdateStatus status) async {
    final url = Platform.isAndroid 
        ? status.androidStoreUrl 
        : status.iosStoreUrl;

    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
