import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../domain.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.controller, super.key});

  final CustomerController controller;

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Saved profile aur connected store is device se remove ho jayenge.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) await controller.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final CustomerProfile profile = controller.profile!;
    final CustomerStore store = controller.selectedStore!;
    final ThemeData theme = Theme.of(context);
    return ListView(
      key: const PageStorageKey<String>('profile-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF145A3B), Color(0xFF287C58)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFFFCE62),
                child: Text(
                  profile.name.trim().isEmpty
                      ? '?'
                      : profile.name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '+91 ${profile.mobile}',
                      style: const TextStyle(color: Color(0xFFD9F2E5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Connected store',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: const Icon(Icons.storefront_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            store.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(store.code, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(store.address),
                const Divider(height: 24),
                Row(
                  children: <Widget>[
                    const Icon(Icons.delivery_dining_rounded, size: 19),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text('Delivery: ${store.expectedDeliveryTime}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: controller.changeStore,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Change store'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('Need help?'),
                subtitle: const Text(
                  'Apni connected kirana store se contact karein.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Store contact details catalogue header mein milengi.',
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Sign out',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => _confirmSignOut(context),
              ),
            ],
          ),
        ),
        if (controller.sessionWarning != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            controller.sessionWarning!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}
