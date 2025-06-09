import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/database_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopntask/services/export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 8),
            // Account Section
            _buildSection(
              title: 'Account',
              items: [
                _buildSettingsItem(
                  icon: FontAwesomeIcons.user,
                  iconColor: CupertinoColors.systemBlue,
                  title: 'Profile',
                  onTap: () {
                    // Handle profile tap
                  },
                ),
                _buildSettingsItem(
                  icon: FontAwesomeIcons.bell,
                  iconColor: CupertinoColors.systemRed,
                  title: 'Notifications',
                  onTap: () {
                    // Handle notifications tap
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Preferences Section
            _buildSection(
              title: 'Preferences',
              items: [
                _buildSettingsItem(
                  icon: FontAwesomeIcons.palette,
                  iconColor: CupertinoColors.systemPurple,
                  title: 'Appearance',
                  onTap: () {
                    // Handle appearance tap
                  },
                ),
                _buildSettingsItem(
                  icon: FontAwesomeIcons.language,
                  iconColor: CupertinoColors.systemGreen,
                  title: 'Language',
                  onTap: () {
                    // Handle language tap
                  },
                ),
                _buildSettingsItem(
                  icon: FontAwesomeIcons.dollarSign,
                  iconColor: CupertinoColors.systemTeal,
                  title: 'Currency',
                  onTap: () {
                    // Handle currency tap
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Data Management Section
            _buildSection(
              title: 'Data Management',
              items: [
                _buildSettingsItem(
                  icon: FontAwesomeIcons.database,
                  iconColor: CupertinoColors.systemIndigo,
                  title: 'Storage',
                  onTap: () {
                    // Handle storage tap
                  },
                ),
                _buildSettingsItem(
                  icon: FontAwesomeIcons.fileExport,
                  iconColor: CupertinoColors.systemOrange,
                  title: 'Export Data',
                  onTap: () async {
                    try {
                      final exportService = context.read<ExportService>();
                      await exportService.exportToCSV();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data exported successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error exporting data: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                _buildSettingsItem(
                  icon: FontAwesomeIcons.fileImport,
                  iconColor: CupertinoColors.systemPink,
                  title: 'Import Data',
                  onTap: () {
                    // Handle import tap
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Support Section
            _buildSection(
              title: 'Support',
              items: [
                _buildSettingsItem(
                  icon: FontAwesomeIcons.circleQuestion,
                  iconColor: CupertinoColors.systemBlue,
                  title: 'Help & Support',
                  onTap: () {
                    // Handle help tap
                  },
                ),
                _buildSettingsItem(
                  icon: FontAwesomeIcons.bug,
                  iconColor: CupertinoColors.systemRed,
                  title: 'Report a Problem',
                  onTap: () {
                    // Handle report tap
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // About Section
            _buildSection(
              title: 'About',
              items: [
                _buildSettingsItem(
                  icon: FontAwesomeIcons.info,
                  iconColor: CupertinoColors.systemBlue,
                  title: 'About HopnTask',
                  onTap: () {
                    // Handle about tap
                  },
                ),
                _buildSettingsItem(
                  icon: FontAwesomeIcons.shield,
                  iconColor: CupertinoColors.systemGreen,
                  title: 'Privacy Policy',
                  onTap: () {
                    // Handle privacy tap
                  },
                ),
                _buildSettingsItem(
                  icon: FontAwesomeIcons.fileContract,
                  iconColor: CupertinoColors.systemPurple,
                  title: 'Terms of Service',
                  onTap: () {
                    // Handle terms tap
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Version Info
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            border: Border(
              top: BorderSide(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
              bottom: BorderSide(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.systemGrey5,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: CupertinoColors.label,
                fontSize: 17,
              ),
            ),
            const Spacer(),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 