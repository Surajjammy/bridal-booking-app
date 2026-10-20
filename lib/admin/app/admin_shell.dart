import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/admin_colors.dart';
import '../features/auth/presentation/provider/admin_auth_provider.dart';
import 'admin_routes.dart';

class _Destination {
  final String label;
  final IconData icon;
  final String route;

  const _Destination(this.label, this.icon, this.route);
}

const _destinations = [
  _Destination('Artists', Icons.brush_outlined, AdminRoutes.artists),
];

/// Page frame: a dark sidebar on wide screens, a drawer on narrow ones.
class AdminShell extends StatelessWidget {
  static const double _wideBreakpoint = 960;
  static const double _sidebarWidth = 248;

  final String location;
  final Widget child;

  const AdminShell({super.key, required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    final sidebar = _Sidebar(location: location);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: _sidebarWidth, child: sidebar),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Admin')),
          drawer: Drawer(
            backgroundColor: AdminColors.sidebar,
            child: sidebar,
          ),
          body: child,
        );
      },
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final String location;

  const _Sidebar({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final email = ref.watch(adminUserProvider).value?.email ?? '';

    return ColoredBox(
      color: AdminColors.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Makeup Artist Booking',
                    style: text.titleMedium?.copyWith(
                      color: AdminColors.champagne,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Admin panel',
                    style: text.bodySmall?.copyWith(
                      color: AdminColors.textOnSidebar,
                    ),
                  ),
                ],
              ),
            ),
            for (final destination in _destinations)
              _NavItem(
                destination: destination,
                selected: location.startsWith(destination.route),
              ),
            const Spacer(),
            const Divider(color: Color(0x1FFFFFFF), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: AdminColors.textOnSidebar,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout,
                        color: AdminColors.textOnSidebar, size: 20),
                    onPressed: () =>
                        ref.read(adminAuthRepositoryProvider).signOut(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Destination destination;
  final bool selected;

  const _NavItem({required this.destination, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AdminColors.champagne : AdminColors.textOnSidebar;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? const Color(0x1AE8C9A0) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(destination.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(destination.icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
