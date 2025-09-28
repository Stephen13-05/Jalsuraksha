import 'package:flutter/material.dart';

class AshaWorkerOfflineSyncPage extends StatelessWidget {
  const AshaWorkerOfflineSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 12),
            Text(
              'Pending Uploads',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'All forms submitted without network will appear here. '
              'When connectivity is available or via Bluetooth sync, they will be uploaded automatically.',
            ),
            SizedBox(height: 24),
            Text(
              'This screen is a placeholder. Store queued form data locally and show status '
              'with retry actions when implementing offline sync.',
            ),
          ],
        ),
      ),
    );
  }
}
