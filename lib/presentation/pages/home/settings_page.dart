import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/circle_provider.dart';
import '../auth/login_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final circleAsync = ref.watch(circleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          profileAsync.when(
            loading: () => const ListTile(
              leading: CircleAvatar(child: CircularProgressIndicator()),
              title: Text('Loading...'),
            ),
            error: (e, s) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.error)),
              title: const Text('Error loading profile'),
            ),
            data: (profile) => Column(
              children: [
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    profile?.fullName?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?.fullName ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  profile?.email ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          const Divider(),

          // Circle Section
          circleAsync.when(
            loading: () => const ListTile(
              title: Text('Loading circle...'),
            ),
            error: (e, s) => const ListTile(
              title: Text('Error loading circle'),
            ),
            data: (circle) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.group),
                  title: Text(circle?.name ?? 'No circle'),
                  subtitle: const Text('Your family circle'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Edit circle
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Invite Code'),
                  subtitle: Text(circle?.inviteCode ?? '-'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Location Settings
          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: const Text('Location Sharing'),
            subtitle: const Text('Share your location with circle'),
            value: true,
            onChanged: (value) {
              // Toggle location sharing
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive place alerts'),
            value: true,
            onChanged: (value) {
              // Toggle notifications
            },
          ),

          const Divider(),

          // Account
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Edit profile
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () => _showSignOutDialog(context, ref),
          ),

          const SizedBox(height: 24),
          
          // App Info
          Center(
            child: Text(
              'Family Tracker v1.0.0',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
