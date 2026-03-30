import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/circle_provider.dart';
import '../../providers/settings_provider.dart';
import '../auth/login_page.dart';
import 'profile_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final circleAsync = ref.watch(circleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          // Profile Section
          profileAsync.when(
            loading: () => const ListTile(
              leading: CircleAvatar(child: CircularProgressIndicator()),
              title: Text('Cargando...'),
            ),
            error: (e, s) => const ListTile(
              leading: CircleAvatar(child: Icon(Icons.error)),
              title: Text('Error al cargar perfil'),
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
                  profile?.fullName ?? 'Desconocido',
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
              title: Text('Cargando círculo...'),
            ),
            error: (e, s) => const ListTile(
              title: Text('Error al cargar círculo'),
            ),
            data: (circle) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.group),
                  title: Text(circle?.name ?? 'Sin círculo'),
                  subtitle: const Text('Tu círculo familiar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Edit circle
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Código de invitación'),
                  subtitle: Text(circle?.inviteCode ?? '-'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      if (circle?.inviteCode != null) {
                        Clipboard.setData(ClipboardData(text: circle!.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('¡Código copiado!')),
                        );
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Salir del Círculo', style: TextStyle(color: Colors.red)),
                  onTap: () => _showLeaveCircleDialog(context, ref),
                ),
              ],
            ),
          ),

          const Divider(),

          // Location Settings
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              return Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.location_on),
                    title: const Text('Compartir Ubicación'),
                    subtitle: const Text('Compartir tu ubicación con el círculo'),
                    value: settings.locationSharing,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleLocationSharing(value);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('Notificaciones'),
                    subtitle: const Text('Recibir alertas de lugares'),
                    value: settings.pushNotifications,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).togglePushNotifications(value);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Intervalo de Actualización'),
                    subtitle: Text('${settings.trackingIntervalSeconds} segundos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showIntervalDialog(context, ref, settings.trackingIntervalSeconds),
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // Account
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Editar Perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
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
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showLeaveCircleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del Círculo'),
        content: const Text('¿Estás seguro de que quieres salir de este círculo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(circleNotifierProvider.notifier).leaveCircle();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saliste del círculo exitosamente')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _showIntervalDialog(BuildContext context, WidgetRef ref, int currentInterval) {
    final intervals = [15, 30, 60, 120, 300];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Intervalo de Actualización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            String label;
            if (interval < 60) {
              label = '$interval segundos';
            } else if (interval < 3600) {
              label = '${interval ~/ 60} minuto${interval ~/ 60 > 1 ? 's' : ''}';
            } else {
              label = '${interval ~/ 3600} hora${interval ~/ 3600 > 1 ? 's' : ''}';
            }
            return RadioListTile<int>(
              title: Text(label),
              value: interval,
              groupValue: currentInterval,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setTrackingInterval(value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Intervalo establecido a $label')),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
