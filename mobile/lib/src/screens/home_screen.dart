import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../providers/sync_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghana Sanitation'),
        actions: [
          Consumer<SyncProvider>(
            builder: (context, syncProvider, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Row(
                    children: [
                      Icon(
                        syncProvider.isOnline
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        syncProvider.isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildReportsTab(),
          _buildSubmitTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        final failed = reportProvider.reports.where((r) => r.failed == true).toList();

        if (reportProvider.reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No reports yet',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (failed.isNotEmpty) ...[
              const Text('Failed uploads', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: failed.map((report) {
                  return Card(
                    color: Colors.red.shade50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(report.category.replaceAll('_', ' ').toUpperCase()),
                      subtitle: Text('Failed after ${report.retryCount} attempts'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => reportProvider.retryReport(report.localId ?? report.id ?? ''),
                            child: const Text('Retry'),
                          ),
                          TextButton(
                            onPressed: () => reportProvider.cancelReport(report.localId ?? report.id ?? ''),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // All reports list
            ...reportProvider.reports.map((report) {
              final progressKey = report.id ?? report.localId ?? '';
              final progress = reportProvider.getUploadProgress(progressKey);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      Icons.report_problem,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(report.category.replaceAll('_', ' ').toUpperCase()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Status: ${report.status}'),
                      Text(
                        'Synced: ${report.isSynced ? 'Yes' : 'No'}',
                        style: TextStyle(
                          color: report.isSynced ? Colors.green : Colors.orange,
                        ),
                      ),
                      if (!report.isSynced && progress > 0.0 && progress < 1.0) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 4),
                        Text('${(progress * 100).toStringAsFixed(0)}% uploading'),
                      ],
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildSubmitTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/camera');
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/report/form');
            },
            icon: const Icon(Icons.form),
            label: const Text('Fill Form'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _buildProfileField(
                label: 'Phone Number',
                value: authProvider.phoneNumber ?? 'Not set',
              ),
              const SizedBox(height: 16),
              _buildProfileField(
                label: 'User ID',
                value: authProvider.user?.id ?? 'Not set',
              ),
              const SizedBox(height: 16),
              _buildProfileField(
                label: 'Role',
                value: authProvider.user?.role ?? 'Citizen',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: AppTheme.bodyMedium),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
