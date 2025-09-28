import 'package:flutter/material.dart';

class AshaWorkerBluetoothSyncPage extends StatelessWidget {
  const AshaWorkerBluetoothSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Sync'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 12),
            Text(
              'Nearby Devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Scanning for ASHA worker devices with Jal Suraksha app. '
              'When a device is detected, non-synced surveys will be securely shared over Bluetooth.',
            ),
            SizedBox(height: 24),
            Center(
              child: CircularProgressIndicator(),
            ),
            SizedBox(height: 24),
            Text(
              'This screen is a placeholder. Integrate platform-specific Bluetooth discovery '
              'and data handoff workflows here.',
            ),
          ],
        ),
      ),
    );
  }
}
