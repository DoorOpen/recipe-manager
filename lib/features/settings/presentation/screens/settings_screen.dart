import 'package:flutter/material.dart';
import '../../../../shared/constants/app_constants.dart';

/// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: 'General',
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                subtitle: const Text('System default'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Theme selector
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Units'),
                subtitle: const Text('Imperial'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Unit selector
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Data',
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Sync'),
                subtitle: const Text('Not connected'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Sync settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export Data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Export
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Import Data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Import
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outlined),
                title: const Text('Version'),
                trailing: Text(
                  AppConstants.appVersion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Report a Bug'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // TODO: Open bug report
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}
