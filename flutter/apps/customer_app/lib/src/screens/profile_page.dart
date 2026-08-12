import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../customer_ui.dart';
import '../domain.dart';

const Color _primary = Color(0xFF078A27);
const Color _primaryLight = Color(0xFFE9F7EA);
const Color _background = Color(0xFFFCFCFA);
const Color _border = Color(0xFFE7E9E4);
const Color _text = Color(0xFF111310);
const Color _mutedText = Color(0xFF686C66);
const Color _danger = Color(0xFFE01D19);

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.controller, super.key});

  final CustomerController controller;

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Sign out?',
          style: TextStyle(color: _text, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Saved profile aur connected store is device se remove ho jayenge.',
          style: TextStyle(color: _mutedText, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: _text),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) await controller.signOut();
  }

  Future<void> _confirmStoreChange(BuildContext context) async {
    final bool hasBasketItems = controller.cartCount > 0;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Change store?'),
        content: Text(
          hasBasketItems
              ? 'Store change karne par aapki current basket clear ho jayegi.'
              : 'Aap available kirana stores ki list par chale jayenge.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Change store'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      await controller.changeStore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final CustomerProfile profile = controller.profile!;
    final CustomerStore store = controller.selectedStore!;

    return ColoredBox(
      color: _background,
      child: ListView(
        key: const PageStorageKey<String>('profile-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: <Widget>[
          _ProfileHero(profile: profile),
          const SizedBox(height: 19),
          const Text(
            'Connected store',
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _StoreCard(
            store: store,
            onChangeStore: () => _confirmStoreChange(context),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.help_outline_rounded,
            title: 'Need help?',
            subtitle: 'Apni connected kirana store se contact karein.',
            onTap: () => showCustomerStoreContactSheet(context, store: store),
          ),
          const SizedBox(height: 12),
          _SignOutCard(onTap: () => _confirmSignOut(context)),
          if (controller.sessionWarning != null) ...<Widget>[
            const SizedBox(height: 12),
            _SessionWarning(message: controller.sessionWarning!),
          ],
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) {
    final String trimmedName = profile.name.trim();
    final String initial = trimmedName.isEmpty
        ? '?'
        : trimmedName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Color(0xFF047922), Color(0xFF16953A)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A078A27),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD21F),
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: _text,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  trimmedName.isEmpty ? 'Customer' : trimmedName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMobile(profile.mobile),
                  style: const TextStyle(
                    color: Color(0xFFE8F8EC),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.onChangeStore});

  final CustomerStore store;
  final Future<void> Function() onChangeStore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      store.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      store.code,
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            store.address,
            style: const TextStyle(
              color: Color(0xFF41443F),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.access_time_rounded,
                color: _mutedText,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delivery: ${store.expectedDeliveryTime}',
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onChangeStore,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Change store'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              Icon(icon, color: _text, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _text, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          child: Row(
            children: <Widget>[
              Icon(Icons.logout_rounded, color: _danger, size: 21),
              SizedBox(width: 12),
              Text(
                'Sign out',
                style: TextStyle(
                  color: _danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionWarning extends StatelessWidget {
  const _SessionWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8D4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, color: _danger, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _danger,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMobile(String mobile) {
  final String trimmed = mobile.trim();
  if (trimmed.startsWith('+')) return trimmed;
  return '+91 $trimmed';
}
